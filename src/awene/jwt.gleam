import gleam/bit_array
import gleam/dynamic/decode
import gleam/json
import gleam/string
import awene/rsa

pub type Jwt {
  Jwt(header: Header, claims: Claims)
}

pub type Header {
  Header(alg: Algorithm, kid: String)
}

pub type Algorithm {
  HS256
  RS256
}

/// These are the couchdb specific claims that are supported.
pub type Claims {
  Claims(sub: String, roles: List(String))
}

pub fn jwt_decoder() -> decode.Decoder(Jwt) {
  use header <- decode.field("header", header_decoder())
  use claims <- decode.field("claims", claims_decoder())
  decode.success(Jwt(header:, claims:))
}

pub fn header_decoder() -> decode.Decoder(Header) {
  use alg <- decode.field("alg", algorithm_decoder())
  use kid <- decode.field("kid", decode.string)
  decode.success(Header(alg:, kid:))
}

pub fn claims_decoder() -> decode.Decoder(Claims) {
  use sub <- decode.field("sub", decode.string)
  use roles <- decode.field("_couchdb.roles", decode.list(of: decode.string))
  decode.success(Claims(sub:, roles:))
}

pub fn jwt_encoder(jwt: Jwt) -> String {
  json.object([
    #("header", json_header(jwt.header)),
    #("claims", json_claims(jwt.claims)),
  ])
  |> json.to_string
}

fn json_header(header: Header) -> json.Json {
  json.object([
    #("alg", json_algorithm(header.alg)),
    #("kid", json.string(header.kid)),
  ])
}

pub fn header_encoder(header: Header) -> String {
  json_header(header) |> json.to_string()
}

fn json_claims(claims: Claims) -> json.Json {
  json.object([
    #("sub", json.string(claims.sub)),
    #("_couchdb.roles", json.array(claims.roles, of: json.string)),
  ])
}

pub fn claims_encoder(claims: Claims) -> String {
  json_claims(claims) |> json.to_string()
}

fn algorithm_decoder() -> decode.Decoder(Algorithm) {
  use alg_string <- decode.then(decode.string)
  case alg_string {
    "HS256" -> decode.success(HS256)
    "RS256" -> decode.success(RS256)
    _ -> decode.failure(HS256, "Only HS256 and RS256 are supported")
  }
}

fn json_algorithm(alg: Algorithm) -> json.Json {
  case alg {
    HS256 -> json.string("HS256")
    RS256 -> json.string("RS256")
  }
}

pub fn encode(jwt: Jwt, key: String) -> Result(String, String) {
  let header_string = header_encoder(jwt.header)
  let claims_string = claims_encoder(jwt.claims)
  let header_base64url =
    bit_array.base64_url_encode(<<header_string:utf8>>, False)
  let claims_base64url =
    bit_array.base64_url_encode(<<claims_string:utf8>>, False)
  let message = <<header_base64url:utf8, ".":utf8, claims_base64url:utf8>>
  let signature_result = rsa.sign(message, <<key:utf8>>)

  case signature_result {
    Ok(signature) -> {
      let signature_base64url = bit_array.base64_url_encode(signature, False)
      let string_result =
        bit_array.to_string(<<message:bits, ".":utf8, signature_base64url:utf8>>)
      case string_result {
        Error(_) -> Error("Bad String")
        Ok(x) -> Ok(x)
      }
    }
    Error(x) -> Error(x)
  }
}

pub fn decode(message: String, key: String) -> Result(Jwt, String) {
  case string.split(message, on: ".") {
    [header, claims, signature] -> {
      verify(header, claims, key, signature)
    }
    _ -> Error("Invalid Jwt String")
  }
}

fn verify(
  header: String,
  claims: String,
  key: String,
  signature: String,
) -> Result(Jwt, String) {
  case bit_array.base64_url_decode(signature) {
    Ok(signature_bit_array) -> {
      let verification =
        rsa.verify(
          <<header:utf8, ".":utf8, claims:utf8>>,
          signature_bit_array,
          <<key:utf8>>,
        )

      case verification {
        Ok(True) -> decode_base64url(header, claims)
        Ok(False) -> Error("Signature verification failed")
        Error(msg) -> Error(msg)
      }
    }
    Error(_) -> Error("Could not base64url decode signature")
  }
}

fn decode_base64url(
  encoded_header: String,
  encoded_claims: String,
) -> Result(Jwt, String) {
  let header_base64_result = bit_array.base64_url_decode(encoded_header)
  let claims_base64_result = bit_array.base64_url_decode(encoded_claims)

  case header_base64_result, claims_base64_result {
    Ok(header_bit_array), Ok(claims_bit_array) -> {
      let header_result =
        json.parse_bits(header_bit_array, header_decoder())
      let claims_result =
        json.parse_bits(claims_bit_array, claims_decoder())
      case header_result, claims_result {
        Ok(header), Ok(claims) -> Ok(Jwt(header: header, claims: claims))
        _, _ -> Error("Could not decode to Jwt object")
      }
    }
    _, _ -> Error("Failed to base64url decode strings")
  }
}
