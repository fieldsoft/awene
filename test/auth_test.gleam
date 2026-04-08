import awene/couch
import awene/web/admin_info.{type AdminInfo}
import awene/web/awene_user.{type UserCred, UserCred, user_cred_encoder}
import awene_test.{admin_info_setup, http_clean, localurl}
import gleam/http.{Post}
import gleam/http/request.{prepend_header, set_body, set_method}
import gleam/httpc
import gleam/string
import initialize_test.{http_initialize}
import unlock_test.{http_unlock_post}

pub fn auth_test() {
  admin_info_setup(http_clean)
  admin_info_setup(http_unlock_post)
  admin_info_setup(http_initialize)
  admin_info_setup(http_auth)
  admin_info_setup(http_clean)
}

fn http_auth(admin_info: AdminInfo) -> Nil {
  let json =
    UserCred(username: "awene@example.com", password: admin_info.password)
    |> user_cred_encoder()

  let assert Ok(auth_req) = request.to(localurl <> "/login")

  let req =
    auth_req
    |> set_body(json)
    |> prepend_header("content-type", "application/json")
    |> set_method(Post)

  let assert Ok(resp) = httpc.send(req)

  assert string.contains(resp.body, "access_token")
  assert resp.status == 200
}
