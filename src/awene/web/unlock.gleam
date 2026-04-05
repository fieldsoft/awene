import awene/couch.{type UserCtx, session_decoder}
import awene/web
import awene/web/admin_info.{type AdminInfo, admin_info_decoder}
import dream_ets/operations
import gleam/dynamic/decode
import gleam/http.{Delete, Get, Post}
import gleam/http/response
import gleam/httpc.{type HttpError}
import gleam/json
import gleam/list
import wisp.{type Request, type Response}

pub fn unlock_handler(req: Request, ctx: web.Context) -> Response {
  case req.method {
    Get -> get_status(ctx)
    Post -> ock(req, ctx, save_credentials_report)
    Delete -> ock(req, ctx, delete_credentials)
    _ -> wisp.method_not_allowed([Post, Delete, Get])
  }
}

fn report_success(_admin_info: AdminInfo, _ctx: web.Context) -> Response {
  wisp.json_response("{\"message\":\"Unlocked\"}", 200)
}

fn get_status(ctx: web.Context) -> Response {
  let admin_info_result = admin_info.get(ctx)

  case admin_info_result {
    Ok(admin_info) -> check_authorization(admin_info, ctx, report_success)
    Error(_) -> wisp.json_response("{\"message\":\"Locked\"}", 200)
  }
}

/// used for locking and unlocking
fn ock(
  req: Request,
  ctx: web.Context,
  f: fn(AdminInfo, web.Context) -> Response,
) -> Response {
  use json <- wisp.require_json(req)
  let decoded = decode.run(json, admin_info_decoder())

  case decoded {
    Ok(admin_info) -> check_authorization(admin_info, ctx, f)
    Error(_) ->
      wisp.json_response("{\"message\":\"Bad JSON object sent.\"}", 422)
  }
}

fn check_authorization(
  admin_info: AdminInfo,
  ctx: web.Context,
  f: fn(AdminInfo, web.Context) -> Response,
) -> Response {
  let server_resp: Result(response.Response(String), HttpError) =
    couch.verify_basic_auth(
      admin_info.username,
      admin_info.password,
      admin_info.url,
    )

  case server_resp {
    Ok(resp) -> process_admin_auth(resp, admin_info, ctx, f)
    Error(_) ->
      wisp.json_response("{\"message\":\"CouchDB connection failure.\"}", 502)
  }
}

fn process_admin_auth(
  resp: response.Response(String),
  admin_info: AdminInfo,
  ctx: web.Context,
  f: fn(AdminInfo, web.Context) -> Response,
) -> Response {
  case resp.status {
    200 -> inspect_body(resp.body, admin_info, ctx, f)
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
  f: fn(AdminInfo, web.Context) -> Response,
) -> Response {
  let decoded = json.parse(from: json, using: session_decoder())

  case decoded {
    Ok(cs) -> inspect_roles(cs.user_ctx, admin_info, ctx, f)
    Error(_) ->
      wisp.json_response("{\"message\":\"CouchDB sent bad JSON.\"}", 502)
  }
}

fn inspect_roles(
  user_ctx: UserCtx,
  admin_info: AdminInfo,
  ctx: web.Context,
  f: fn(AdminInfo, web.Context) -> Response,
) -> Response {
  let is_member: Bool = list.contains(user_ctx.roles, "_admin")

  case is_member {
    True -> f(admin_info, ctx)
    False -> wisp.json_response("{\"message\":\"Not authorized.\"}", 401)
  }
}

fn save_credentials(
  admin_info: AdminInfo,
  ctx: web.Context,
) -> #(AdminInfo, web.Context) {
  let assert Ok(_) = operations.set(ctx.db, "username", admin_info.username)
  let assert Ok(_) = operations.set(ctx.db, "password", admin_info.password)
  let assert Ok(_) = operations.set(ctx.db, "url", admin_info.url)
  let assert Ok(_) =
    operations.set(ctx.db, "private_key", admin_info.private_key)
  let assert Ok(_) = operations.set(ctx.db, "public_key", admin_info.public_key)
  let assert Ok(_) = operations.set(ctx.db, "key_id", admin_info.key_id)

  #(admin_info, ctx)
}

fn save_credentials_report(admin_info: AdminInfo, ctx: web.Context) -> Response {
  save_credentials(admin_info, ctx)

  report_success(admin_info, ctx)
}

fn delete_credentials(_admin_info: AdminInfo, ctx: web.Context) -> Response {
  let assert Ok(_) = operations.delete_all_objects(ctx.db)

  wisp.json_response("{\"message\":\"Locked\"}", 200)
}
