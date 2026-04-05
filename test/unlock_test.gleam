import awene_test.{localurl, admin_info_setup}
import gleam/http.{Delete, Get, Post}
import gleam/http/request.{type Request}
import gleam/httpc
import awene/web/admin_info.{type AdminInfo, AdminInfo}

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
