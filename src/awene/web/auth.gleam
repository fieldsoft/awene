import awene/couch
import awene/jwt
import awene/passwords
import awene/web
import awene/web/admin_info.{type AdminInfo}
import awene/web/awene_user.{
  type AweneUser, awene_user_decoder, user_cred_decoder,
}
import gleam/dynamic/decode
import gleam/float
import gleam/http.{Post}
import gleam/http/response
import gleam/httpc.{type HttpError}
import gleam/json
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import wisp.{type Request, type Response}

pub type RespObj {
  RespObj(access_token: String, token_type: String)
}

pub fn resp_obj_encoder(resp: RespObj) -> String {
  json.object([
    #("access_token", json.string(resp.access_token)),
    #("token_type", json.string(resp.token_type)),
  ])
  |> json.to_string()
}

pub fn resp_obj_decoder() -> decode.Decoder(RespObj) {
  use access_token <- decode.field("access_token", decode.string)
  use token_type <- decode.field("token_type", decode.string)
  decode.success(RespObj(access_token:, token_type:))
}

pub fn auth_handler(req: Request, ctx: web.Context) -> Response {
  case req.method {
    Post -> authenticate(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn authenticate(req, ctx) -> Response {
  case admin_info.get(ctx) {
    Ok(admin_info) -> verify_json_step(admin_info, req)
    Error(_) -> wisp.json_response("{\"message\":\"Locked\"}", 200)
  }
}

fn verify_json_step(admin_info: AdminInfo, req: Request) {
  use json <- wisp.require_json(req)
  let decoded = decode.run(json, user_cred_decoder())

  case decoded {
    Ok(user_cred) ->
      get_user_info_step(user_cred.username, user_cred.password, admin_info)
    Error(_) ->
      wisp.json_response("{\"message\":\"Bad JSON object sent.\"}", 422)
  }
}

fn get_user_info_step(
  username: String,
  password: String,
  admin_info: AdminInfo,
) -> Response {
  let server_resp: Result(response.Response(String), HttpError) =
    couch.get_user_info(
      username,
      admin_info.username,
      admin_info.password,
      admin_info.url,
    )

  case server_resp {
    Ok(resp) -> process_server_response_step(resp, password, admin_info)
    Error(_) ->
      wisp.json_response("{\"message\":\"CouchDB connection failure.\"}", 502)
  }
}

fn process_server_response_step(
  resp: response.Response(String),
  password: String,
  admin_info: AdminInfo,
) -> Response {
  case resp.status {
    200 -> inspect_body_step(resp.body, password, admin_info)
    401 ->
      wisp.json_response("{\"message\":\"CouchDB authorization failed.\"}", 502)
    otherwise ->
      wisp.json_response(
        "{\"message\":\"CouchDB had non-200 status.\"}",
        otherwise,
      )
  }
}

fn inspect_body_step(
  json: String,
  password: String,
  admin_info: AdminInfo,
) -> Response {
  let decoded = json.parse(json, awene_user_decoder())

  case decoded {
    Ok(awene_user) -> check_password_step(awene_user, password, admin_info)
    Error(_) ->
      wisp.json_response("{\"message\":\"CouchDB sent bad JSON.\"}", 502)
  }
}

fn check_password_step(
  awene_user: AweneUser,
  password: String,
  admin_info: AdminInfo,
) -> Response {
  let verification = passwords.verify(password, awene_user.password_hash)

  case verification {
    True -> create_and_sign_jwt_step(awene_user, admin_info)
    False -> wisp.json_response("{\"message\":\"Authentication failure\"}", 401)
  }
}

fn create_and_sign_jwt_step(
  awene_user: AweneUser,
  admin_info: AdminInfo,
) -> Response {
  let exp_time =
    timestamp.system_time()
    |> timestamp.add(duration.hours(1))
    |> timestamp.to_unix_seconds()
    |> float.round

  case string.split(awene_user.id, ":") {
    [_, user] -> {
      let token =
        jwt.Jwt(
          header: jwt.Header(alg: jwt.RS256, kid: admin_info.key_id),
          claims: jwt.Claims(sub: user, roles: awene_user.roles, exp: exp_time),
        )
      let result = jwt.encode(token, admin_info.private_key)

      case result {
        Ok(signed) -> prepare_response_step(signed)
        Error(_) ->
          wisp.json_response("{\"message\":\"Token signing error.\"}", 500)
      }
    }
    _ ->
      wisp.json_response("{\"message\":\"Awene user object has bad id.\"}", 500)
  }
}

fn prepare_response_step(signed: String) -> Response {
  RespObj(access_token: signed, token_type: "Bearer")
  |> resp_obj_encoder()
  |> wisp.json_response(200)
}
