import gleam/dynamic/decode
import gleam/json
import awene/web
import gleam/option.{Some, None, type Option}
import dream_ets/operations
import gleam/result

pub type AdminInfo {
  AdminInfo(
    username: String,
    password: String,
    url: String,
    private_key: String,
    public_key: String,
    key_id: String,
  )
}

pub fn admin_info_decoder() -> decode.Decoder(AdminInfo) {
  use username <- decode.field("username", decode.string)
  use password <- decode.field("password", decode.string)
  use url <- decode.field("url", decode.string)
  use private_key <- decode.field("private_key", decode.string)
  use public_key <- decode.field("public_key", decode.string)
  use key_id <- decode.field("key_id", decode.string)
  decode.success(AdminInfo(
    username:,
    password:,
    url:,
    private_key:,
    public_key:,
    key_id:,
  ))
}

pub fn admin_info_encoder(admin_info: AdminInfo) -> String {
  json.object([
    #("username", json.string(admin_info.username)),
    #("password", json.string(admin_info.password)),
    #("url", json.string(admin_info.url)),
    #("private_key", json.string(admin_info.private_key)),
    #("public_key", json.string(admin_info.public_key)),
    #("key_id", json.string(admin_info.key_id)),
  ])
  |> json.to_string
}

pub fn get(ctx: web.Context) -> Result(AdminInfo, String) {
  use username <- result.try(m(operations.get(ctx.db, "username")))
  use password <- result.try(m(operations.get(ctx.db, "password")))
  use url <- result.try(m(operations.get(ctx.db, "url")))
  use private_key <- result.try(m(operations.get(ctx.db, "private_key")))
  use public_key <- result.try(m(operations.get(ctx.db, "public_key")))
  use key_id <- result.try(m(operations.get(ctx.db, "key_id")))

  Ok(AdminInfo(
    username: username,
    password: password,
    url: url,
    private_key: private_key,
    public_key: public_key,
    key_id: key_id,
  ))
}

fn m(in: Result(Option(String), y)) -> Result(String, String) {
  case in {
    Ok(op) ->
      case op {
        Some(s) -> Ok(s)
        None -> Error("no value")
      }
    Error(_) -> Error("table error")
  }
}
