import gleam/dynamic/decode
import gleam/json

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
