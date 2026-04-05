import awene_test.{admin_info_setup}
import awene/web/admin_info.{type AdminInfo}
import awene/web/jwt
import gleam/json

pub fn http_jwt_sign_test() {
  admin_info_setup(jwt_sign_test)
}

pub fn http_jwt_verify_test() {
  admin_info_setup(jwt_verify_test)
}

pub fn jwt_header_json_test() {
  let header = jwt.Header(alg: jwt.RS256, kid: "test")
  let header_encoded = jwt.header_encoder(header)
  let assert Ok(header_decoded) = json.parse(from: header_encoded, using: jwt.header_decoder())
  assert header_decoded == header
}

pub fn jwt_claims_json_test() {
  let claims = jwt.Claims(sub: "user", roles: [])
  let claims_encoded = jwt.claims_encoder(claims)
  let assert Ok(claims_decoded) = json.parse(from: claims_encoded, using: jwt.claims_decoder())
  assert claims_decoded == claims
}

fn jwt_sign_test(admin_info: AdminInfo) -> Nil {
  let jwt =
    jwt.Jwt(
      header: jwt.Header(alg: jwt.RS256, kid: admin_info.key_id),
      claims: jwt.Claims(sub: "user", roles: []),
    )

  let assert Ok(_jwt_signed) = jwt.encode(jwt, admin_info.private_key)

  Nil
}

fn jwt_verify_test(admin_info: AdminInfo) -> Nil {
  let jwt =
    jwt.Jwt(
      header: jwt.Header(alg: jwt.RS256, kid: admin_info.key_id),
      claims: jwt.Claims(sub: "user", roles: []),
    )

  let assert Ok(jwt_signed) = jwt.encode(jwt, admin_info.private_key)
  let assert Ok(jwt_verified) = jwt.decode(jwt_signed, admin_info.public_key)

  assert jwt_verified == jwt
}
