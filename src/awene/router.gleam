import awene/web
import awene/web/admin_info
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["unlock"] -> admin_info.unlock_handler(req, ctx)
    _ -> wisp.not_found()
  }
  
  // use <- wisp.require_method(req, Post)

  // use json <- wisp.require_json(req)

  // let result = {
  //   use person <- result.try(decode.run(json, person_decoder()))

  //   let object =
  //     json.object([
  //       #("name", json.string(person.name)),
  //       #("is-cool", json.bool(person.is_cool)),
  //       #("saved", json.bool(True)),
  //     ])
  //   Ok(json.to_string(object))
  // }

  // case result {
  //   Ok(json) -> wisp.json_response(json, 201)
  //   Error(_) -> wisp.unprocessable_content()
  // }
}
