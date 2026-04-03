import gleeunit
import dot_env as dot
import dot_env/env
import gleam/io
import gleam/result
import gleam/http.{Post,Delete,Get}
import gleam/http/request.{type Request}
import gleam/httpc
import awene/web/admin_info.{type AdminInfo, AdminInfo}
import gleam/erlang/process
import awene

const localurl = "http://localhost:8080"

pub fn main() -> Nil {
  process.spawn(awene.main)
  gleeunit.main()
}

fn admin_info_setup(f: fn (AdminInfo) -> Nil) -> Nil {
  let admin_info = admin_info_from_env()
  
  case admin_info {
    Ok(value) -> f(value)
    Error(_) -> io.println("Set TEST_* values in .env to run HTTP API tests")
  }
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

fn http_unlock_get_after_post() -> Nil {
  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req : Request(String) =
    unlock_req
    |> request.set_method(Get)

  let assert Ok(resp) =
    httpc.send(req)

  assert 200 == resp.status
  assert "{\"message\":\"Unlocked\"}" == resp.body
}

fn http_unlock_get_after_delete() -> Nil {
  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req : Request(String) =
    unlock_req
    |> request.set_method(Get)

  let assert Ok(resp) =
    httpc.send(req)

  assert 200 == resp.status
  assert "{\"message\":\"Locked\"}" == resp.body
}

fn http_unlock_post(admin_info: AdminInfo) -> Nil {
  let json = admin_info.admin_info_encoder(admin_info)
  
  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req : Request(String) =
    unlock_req
    |> request.set_body(json)
    |> request.set_header("content-type", "application/json")
    |> request.set_method(Post)

  let assert Ok(resp) =
    httpc.send(req)

  assert 200 == resp.status
  assert "{\"message\":\"Unlocked\"}" == resp.body
}

fn http_unlock_delete(admin_info: AdminInfo) -> Nil {
  let json = admin_info.admin_info_encoder(admin_info)
  
  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req : Request(String) =
    unlock_req
    |> request.set_body(json)
    |> request.set_header("content-type", "application/json")
    |> request.set_method(Delete)

  let assert Ok(resp) =
    httpc.send(req)

  assert 200 == resp.status
  assert "{\"message\":\"Locked\"}" == resp.body
}

fn http_unlock_post_unauthorized(admin_info: AdminInfo) -> Nil {
  let json = admin_info.admin_info_encoder(AdminInfo(..admin_info, password: ""))
  
  let assert Ok(unlock_req) = request.to(localurl <> "/unlock")

  let req : Request(String) =
    unlock_req
    |> request.set_body(json)
    |> request.set_header("content-type", "application/json")
    |> request.set_method(Post)

  let assert Ok(resp) =
    httpc.send(req)

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

  Ok(AdminInfo(username: testadmin,
    password: testpass,
    url: testurl,
    private_key: testpriv,
    public_key: testpub,
  ))
}
