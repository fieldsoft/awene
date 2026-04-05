import awene
import awene/web/admin_info.{type AdminInfo, AdminInfo}
import awene/web/jwt
import dot_env as dot
import dot_env/env
import gleam/erlang/process
import gleam/http.{Delete, Get, Post}
import gleam/http/request.{type Request}
import gleam/httpc
import gleam/io
import gleam/result
import gleeunit
import gleam/dynamic
import gleam/json

const localurl = "http://localhost:8080"

pub fn main() -> Nil {
  process.spawn(awene.main)
  gleeunit.main()
}

fn admin_info_setup(f: fn(AdminInfo) -> Nil) -> Nil {
  let admin_info = admin_info_from_env()

  case admin_info {
    Ok(value) -> f(value)
    Error(_) -> io.println("Set TEST_* values in .env to run HTTP API tests")
  }
}

pub fn http_jwt_sign_test() {
  admin_info_setup(jwt_sign_test)
}

pub fn http_jwt_verify_test() {
  admin_info_setup(jwt_verify_test)
}

pub fn http_unlock_post_test() {
  admin_info_setup(http_unlock_post)
  http_unlock_get_after_post()
}

pub fn http_unlock_post_unauthorized_test() {
  admin_info_setup(http_unlock_post_unauthorized)
}

pub fn http_unlock_delete_test() {
  admin_info_setup(http_unlock_delete)
  http_unlock_get_after_delete()
}

pub fn http_unlock_post_delete_test() {
  admin_info_setup(http_unlock_post)
  http_unlock_get_after_post()
  admin_info_setup(http_unlock_delete)
  http_unlock_get_after_delete()
}

pub fn http_unlock_post_delete_post_test() {
  admin_info_setup(http_unlock_post)
  http_unlock_get_after_post()
  admin_info_setup(http_unlock_delete)
  http_unlock_get_after_delete()
  admin_info_setup(http_unlock_post)
  http_unlock_get_after_post()
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

fn http_unlock_get_after_post() -> Nil {
  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req: Request(String) =
    unlock_req
    |> request.set_method(Get)

  let assert Ok(resp) = httpc.send(req)

  assert 200 == resp.status
  assert "{\"message\":\"Unlocked\"}" == resp.body
}

fn http_unlock_get_after_delete() -> Nil {
  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req: Request(String) =
    unlock_req
    |> request.set_method(Get)

  let assert Ok(resp) = httpc.send(req)

  assert 200 == resp.status
  assert "{\"message\":\"Locked\"}" == resp.body
}

fn http_unlock_post(admin_info: AdminInfo) -> Nil {
  let json = admin_info.admin_info_encoder(admin_info)

  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req: Request(String) =
    unlock_req
    |> request.set_body(json)
    |> request.set_header("content-type", "application/json")
    |> request.set_method(Post)

  let assert Ok(resp) = httpc.send(req)

  assert 200 == resp.status
  assert "{\"message\":\"Unlocked\"}" == resp.body
}

fn http_unlock_delete(admin_info: AdminInfo) -> Nil {
  let json = admin_info.admin_info_encoder(admin_info)

  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req: Request(String) =
    unlock_req
    |> request.set_body(json)
    |> request.set_header("content-type", "application/json")
    |> request.set_method(Delete)

  let assert Ok(resp) = httpc.send(req)

  assert 200 == resp.status
  assert "{\"message\":\"Locked\"}" == resp.body
}

fn http_unlock_post_unauthorized(admin_info: AdminInfo) -> Nil {
  let json =
    admin_info.admin_info_encoder(AdminInfo(..admin_info, password: ""))

  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req: Request(String) =
    unlock_req
    |> request.set_body(json)
    |> request.set_header("content-type", "application/json")
    |> request.set_method(Post)

  let assert Ok(resp) = httpc.send(req)

  assert 401 == resp.status
  assert "{\"message\":\"Not authorized.\"}" == resp.body
}

fn admin_info_from_env() -> Result(AdminInfo, String) {
  dot.new_with_path(".env")
  |> dot.load

  use testadmin <- result.try(env.get_string("TEST_ADMIN"))
  use testpass <- result.try(env.get_string("TEST_PASSWORD"))
  use testurl <- result.try(env.get_string("TEST_URL"))
  use testpriv <- result.try(env.get_string("TEST_PRIVATE_KEY"))
  use testpub <- result.try(env.get_string("TEST_PUBLIC_KEY"))
  use testid <- result.try(env.get_string("TEST_KEY_ID"))

  Ok(AdminInfo(
    username: testadmin,
    password: testpass,
    url: testurl,
    private_key: testpriv,
    public_key: testpub,
    key_id: testid,
  ))
}
