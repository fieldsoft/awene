import awene
import awene/web/admin_info.{type AdminInfo, AdminInfo}
import dot_env as dot
import dot_env/env
import gleam/erlang/process
import gleam/io
import gleam/result
import gleeunit
import awene/couch

pub const localurl = "http://localhost:8080"

pub fn main() -> Nil {
  process.spawn(awene.main)
  gleeunit.main()
}

pub fn admin_info_setup(f: fn(AdminInfo) -> Nil) -> Nil {
  let admin_info = admin_info_from_env()

  case admin_info {
    Ok(value) -> f(value)
    Error(_) -> io.println("Set TEST_* values in .env to run HTTP API tests")
  }
}

pub fn http_clean(admin_info: AdminInfo) -> Nil {
  let assert Ok(resp) =
    couch.delete_db(
      "awene",
      admin_info.username,
      admin_info.password,
      admin_info.url,
    )
  assert resp.status == 200 || resp.status == 404
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
