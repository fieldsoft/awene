import awene/couch
import awene/web
import dream_ets/operations
import gleam/dynamic/decode
import gleam/http.{Post}
import gleam/http/response
import gleam/httpc.{type HttpError}
import gleam/json
import gleam/list
import wisp.{type Request, type Response}

pub type AdminInfo {
  AdminInfo(
    username: String,
    password: String,
    url: String,
    private_key: String,
    public_key: String,
  )
}

fn admin_info_decoder() -> decode.Decoder(AdminInfo) {
  use username <- decode.field("username", decode.string)
  use password <- decode.field("password", decode.string)
  use url <- decode.field("url", decode.string)
  use private_key <- decode.field("private_key", decode.string)
  use public_key <- decode.field("public_key", decode.string)
  decode.success(AdminInfo(
    username:,
    password:,
    url:,
    private_key:,
    public_key:,
  ))
}

pub type CouchSession {
  CouchSession(user_ctx: UserCtx)
}

fn couch_session_decoder() -> decode.Decoder(CouchSession) {
  use user_ctx <- decode.field("userCtx", user_ctx_decoder())
  decode.success(CouchSession(user_ctx:))
}

pub type UserCtx {
  UserCtx(name: String, roles: List(String))
}

pub fn user_ctx_decoder() -> decode.Decoder(UserCtx) {
  use name <- decode.field("name", decode.string)
  use roles <- decode.field("roles", decode.list(decode.string))
  decode.success(UserCtx(name:, roles:))
}

pub fn unlock_handler(req: Request, ctx: web.Context) -> Response {
  case req.method {
    //   Get -> unlock_status(ctx)
    Post -> unlock(req, ctx)
    //   Delete -> lock(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn unlock(req: Request, ctx: web.Context) -> Response {
  use json <- wisp.require_json(req)
  let decoded = decode.run(json, admin_info_decoder())

  case decoded {
    Ok(admin_info) -> process_info(admin_info, ctx)
    Error(_) ->
      wisp.json_response("{\"message\":\"Bad JSON object sent.\"}", 422)
  }
}

fn process_info(admin_info: AdminInfo, ctx: web.Context) -> Response {
  let server_resp: Result(response.Response(String), HttpError) =
    couch.verify_auth(admin_info.username, admin_info.password, admin_info.url)

  case server_resp {
    Ok(resp) -> process_admin_auth(resp, admin_info, ctx)
    Error(_) ->
      wisp.json_response("{\"message\":\"CouchDB connection failure.\"}", 502)
  }
}

fn process_admin_auth(
  resp: response.Response(String),
  admin_info: AdminInfo,
  ctx: web.Context,
) -> Response {
  case resp.status {
    200 -> inspect_body(resp.body, admin_info, ctx)
    401 -> wisp.json_response("{\"message\":\"Not authorized.\"}", 401)
    otherwise ->
      wisp.json_response(
        "{\"message\":\"CouchDB had non-200 status.\"}",
        otherwise,
      )
  }
}

fn inspect_body(
  json: String,
  admin_info: AdminInfo,
  ctx: web.Context,
) -> Response {
  let decoded = json.parse(from: json, using: couch_session_decoder())

  case decoded {
    Ok(cs) -> inspect_roles(cs.user_ctx, admin_info, ctx)
    Error(_) ->
      wisp.json_response("{\"message\":\"CouchDB sent bad JSON.\"}", 502)
  }
}

fn inspect_roles(
  user_ctx: UserCtx,
  admin_info: AdminInfo,
  ctx: web.Context,
) -> Response {
  let is_member: Bool = list.contains(user_ctx.roles, "_admin")

  case is_member {
    True -> save_credentials(admin_info, ctx)
    False -> wisp.json_response("{\"message\":\"Not authorized.\"}", 401)
  }
}

fn save_credentials(admin_info: AdminInfo, ctx: web.Context) -> Response {
  let assert Ok(_) = operations.set(ctx.db, "username", admin_info.username)
  let assert Ok(_) = operations.set(ctx.db, "password", admin_info.password)
  let assert Ok(_) =
    operations.set(ctx.db, "private_key", admin_info.private_key)
  let assert Ok(_) = operations.set(ctx.db, "public_key", admin_info.public_key)

  wisp.json_response("{\"message\":\"Unlocked\"}", 200)
}
