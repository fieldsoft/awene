import gleam/bit_array.{base64_encode}
import gleam/dynamic/decode
import gleam/http.{Delete, Put}
import gleam/http/request.{
  type Request, prepend_header, set_body, set_method, set_path,
}
import gleam/http/response.{type Response}
import gleam/httpc.{type HttpError}

pub type Session {
  Session(user_ctx: UserCtx)
}

pub fn session_decoder() -> decode.Decoder(Session) {
  use user_ctx <- decode.field("userCtx", user_ctx_decoder())
  decode.success(Session(user_ctx:))
}

pub type UserCtx {
  UserCtx(name: String, roles: List(String))
}

pub fn user_ctx_decoder() -> decode.Decoder(UserCtx) {
  use name <- decode.field("name", decode.string)
  use roles <- decode.field("roles", decode.list(decode.string))
  decode.success(UserCtx(name:, roles:))
}

/// Atempts basic auth to the CouchDB _session database and returns the result. On success, a UserCtx object can be inspected to ensure that the authorized user had the correct roles.
pub fn verify_basic_auth(
  username: String,
  password: String,
  url: String,
) -> Result(Response(String), HttpError) {
  let assert Ok(base_req) = request.to(url <> "/_session")

  let req = set_basic_auth(base_req, username, password)

  httpc.send(req)
}

pub fn get_user_info(
  target: String,
  username: String,
  password: String,
  url: String,
) -> Result(Response(String), HttpError) {
  let assert Ok(base_req) = request.to(url <> "/awene/user:" <> target)

  let req = set_basic_auth(base_req, username, password)

  httpc.send(req)
}

pub fn create_db(
  target: String,
  username: String,
  password: String,
  url: String,
) -> Result(Response(String), HttpError) {
  let assert Ok(base_req) = request.to(url <> "/" <> target)

  let req =
    base_req
    |> set_basic_auth(username, password)
    |> set_method(Put)

  httpc.send(req)
}

pub fn delete_db(
  target: String,
  username: String,
  password: String,
  url: String,
) -> Result(Response(String), HttpError) {
  let assert Ok(base_req) = request.to(url <> "/" <> target)

  let req =
    base_req
    |> set_basic_auth(username, password)
    |> set_method(Delete)

  httpc.send(req)
}

pub fn user(
  json: String,
  userid: String,
  username: String,
  password: String,
  url: String,
) -> Result(Response(String), HttpError) {
  let assert Ok(base_req) = request.to(url <> "/awene/" <> userid)

  let req =
    base_req
    |> set_basic_auth(username, password)
    |> set_method(Put)
    |> set_body(json)
    |> prepend_header("content-type", "application/json")

  httpc.send(req)
}

pub fn set_public_key(
  kid: String,
  public_key_json: String,
  username: String,
  password: String,
  url: String,
) -> Result(Response(String), HttpError) {
  let auth_path = "/_node/_local/_config/chttpd/authentication_handlers"
  let auth_value =
    "\"{chttpd_auth, cookie_authentication_handler}, {chttpd_auth, jwt_authentication_handler}, {chttpd_auth, default_authentication_handler}\""
  let key_path = "/_node/_local/_config/jwt_keys/rsa:" <> kid

  let assert Ok(base_req) = request.to(url)

  let req =
    base_req
    |> set_basic_auth(username, password)
    |> prepend_header("content-type", "application/json")
    |> set_method(Put)

  let auth_req =
    req
    |> set_path(auth_path)
    |> set_body(auth_value)

  let key_req =
    req
    |> set_path(key_path)
    |> set_body(public_key_json)

  let auth_resp = httpc.send(auth_req)

  case auth_resp {
    Ok(resp) -> {
      case resp.status {
        200 -> httpc.send(key_req)
        _ -> auth_resp
      }
    }
    Error(_) -> auth_resp
  }
}

fn set_basic_auth(
  req: Request(body),
  username: String,
  password: String,
) -> Request(body) {
  let credentials: String = username <> ":" <> password

  let creds: String =
    credentials
    |> bit_array.from_string()
    |> base64_encode(True)

  req
  |> prepend_header(
    "www-authenticate",
    "Basic realm=\"None\", charset=\"UTF-8\"",
  )
  |> prepend_header("authorization", "Basic " <> creds)
}
