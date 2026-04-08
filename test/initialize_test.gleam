import awene/web/admin_info.{type AdminInfo}
import awene/web/awene_user.{UserCred, user_cred_encoder}
import awene_test.{admin_info_setup, localurl, http_clean}
import gleam/http.{Post}
import gleam/http/request.{prepend_header, set_body, set_method}
import gleam/httpc
import unlock_test.{http_unlock_post}

pub fn http_initialize_test() {
  admin_info_setup(http_clean)
  admin_info_setup(http_unlock_post)
  admin_info_setup(http_initialize)
  admin_info_setup(http_clean)
}

pub fn http_initialize(admin_info: AdminInfo) -> Nil {
  let json =
    UserCred(username: admin_info.username, password: admin_info.password)
    |> user_cred_encoder()

  let assert Ok(initialize_req) = request.to(localurl <> "/init")

  let req =
    initialize_req
    |> set_body(json)
    |> prepend_header("content-type", "application/json")
    |> set_method(Post)

  let assert Ok(resp) = httpc.send(req)

  assert resp.body == "{\"message\":\"Awene system ready.\"}"
  assert resp.status == 201
}
