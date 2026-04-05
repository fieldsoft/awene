import awene/web
import awene/web/unlock
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["unlock"] -> unlock.unlock_handler(req, ctx)
    _ -> wisp.not_found()
  }
}
