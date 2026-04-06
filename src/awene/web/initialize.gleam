import awene/couch
import awene/passwords
import awene/web
import awene/web/admin_info.{type AdminInfo}
import awene/web/awene_user.{
  AweneUser, awene_user_encode, user_cred_decoder,
}
import gleam/dynamic/decode
import gleam/http.{Post}
import gleam/json
import gleam/option.{None}
import wisp.{type Request, type Response}

pub fn init_handler(req: Request, ctx: web.Context) -> Response {
  case req.method {
    Post -> initialize(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

fn initialize(req, ctx) -> Response {
  case admin_info.get(ctx) {
    Ok(admin_info) -> verify_json_step(admin_info, req)
    Error(_) -> wisp.json_response("{\"message\":\"Locked\"}", 200)
  }
}

fn verify_json_step(admin_info: AdminInfo, req: Request) {
  use json <- wisp.require_json(req)
  let decoded = decode.run(json, user_cred_decoder())

  case decoded {
    Ok(user_cred) -> {
      let authenticated =
        user_cred.username == admin_info.username
        && user_cred.password == admin_info.password
      case authenticated {
        True -> create_database_step(admin_info)
        False ->
          wisp.json_response("{\"message\":\"Authenication failure\"}", 401)
      }
    }
    Error(_) ->
      wisp.json_response("{\"message\":\"Bad JSON object sent.\"}", 422)
  }
}

fn create_database_step(admin_info: AdminInfo) -> Response {
  let server_resp =
    couch.create_db(
      "awene",
      admin_info.username,
      admin_info.password,
      admin_info.url,
    )

  case server_resp {
    Ok(resp) -> {
      case resp.status {
        201 -> create_awene_user_step(admin_info)
        412 ->
          wisp.json_response(
            "{\"message\":\"Awene database already exists.\"}",
            412,
          )
        401 ->
          wisp.json_response(
            "{\"message\":\"CouchDB authorization failed.\"}",
            502,
          )
        otherwise ->
          wisp.json_response(
            "{\"message\":\"CouchDB had non-200 status.\"}",
            otherwise,
          )
      }
    }
    Error(_) ->
      wisp.json_response("{\"message\":\"CouchDB connection failure.\"}", 502)
  }
}

fn create_awene_user_step(admin_info: AdminInfo) -> Response {
  // Rather than a default, the initial password is set equal to the present admin password.
  let assert Ok(password_hash) = passwords.hash(admin_info.password)
  let awene_user =
    AweneUser(
      id: "user:awene@example.com",
      rev: None,
      password_hash: password_hash,
      roles: ["awene"],
    )
    |> awene_user_encode()

  let server_resp =
    couch.user(
      awene_user,
      admin_info.username,
      admin_info.password,
      admin_info.url,
    )

  case server_resp {
    Ok(resp) -> {
      case resp.status {
        201 -> set_public_key_step(admin_info)
        409 ->
          wisp.json_response(
            "{\"message\":\"Awene user already exists.\"}",
            409,
          )
        401 ->
          wisp.json_response(
            "{\"message\":\"CouchDB authentication failed.\"}",
            502,
          )
        403 ->
          wisp.json_response(
            "{\"message\":\"CouchDB authorization failed.\"}",
            502,
          )
        otherwise ->
          wisp.json_response(
            "{\"message\":\"CouchDB had non-200 status.\"}",
            otherwise,
          )
      }
    }
    Error(_) ->
      wisp.json_response("{\"message\":\"CouchDB connection failure.\"}", 502)
  }
}

fn set_public_key_step(admin_info: AdminInfo) {
  let public_key_json =
    admin_info.public_key
    |> json.string()
    |> json.to_string()

  let server_resp =
    couch.set_public_key(
      admin_info.key_id,
      public_key_json,
      admin_info.username,
      admin_info.password,
      admin_info.url,
    )

  case server_resp {
    Ok(resp) -> {
      case resp.status {
        200 -> wisp.json_response("{\"message\":\"Awene system ready.\"}", 201)
        401 ->
          wisp.json_response(
            "{\"message\":\"CouchDB authentication failed.\"}",
            502,
          )
        403 ->
          wisp.json_response(
            "{\"message\":\"CouchDB authorization failed.\"}",
            502,
          )
        otherwise ->
          wisp.json_response(
            "{\"message\":\"CouchDB had non-200 status.\"}",
            otherwise,
          )
      }
    }
    Error(_) ->
      wisp.json_response("{\"message\":\"CouchDB connection failure.\"}", 502)
  }
}
