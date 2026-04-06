import awene/web
import awene/web/unlock
import awene/web/auth
import awene/web/initialize
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["unlock"] -> unlock.unlock_handler(req, ctx)
    ["init"] -> initialize.init_handler(req, ctx)
    ["login"] -> auth.auth_handler(req, ctx)
    _ -> wisp.not_found()
  }
}
