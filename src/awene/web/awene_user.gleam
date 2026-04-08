import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}

pub type AweneUser {
  AweneUser(
    id: String,
    rev: Option(String),
    password_hash: String,
    roles: List(String),
  )
}

pub fn awene_user_decoder() -> decode.Decoder(AweneUser) {
  use id <- decode.field("_id", decode.string)
  use rev <- decode.field("_rev", decode.optional(decode.string))
  use password_hash <- decode.field("password_hash", decode.string)
  use roles <- decode.field("roles", decode.list(decode.string))
  decode.success(AweneUser(id:, rev:, password_hash:, roles:))
}

pub fn awene_user_encode(user: AweneUser) -> String {
  json.object([
    #("_id", json.string(user.id)),
    #("_rev", json.nullable(user.rev, json.string)),
    #("password_hash", json.string(user.password_hash)),
    #("roles", json.array(user.roles, json.string)),
  ])
  |> json.to_string()
}

pub fn new_awene_user_encode(user: AweneUser) -> String {
  json.object([
    #("_id", json.string(user.id)),
    #("password_hash", json.string(user.password_hash)),
    #("roles", json.array(user.roles, json.string)),
  ])
  |> json.to_string()
}

pub type UserCred {
  UserCred(username: String, password: String)
}

pub fn user_cred_decoder() -> decode.Decoder(UserCred) {
  use username <- decode.field("username", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(UserCred(username:, password:))
}

pub fn user_cred_encoder(user_cred: UserCred) {
  json.object([
    #("username", json.string(user_cred.username)),
    #("password", json.string(user_cred.password)),
  ])
  |> json.to_string()
}
