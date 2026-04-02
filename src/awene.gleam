import gleam/erlang/process
import awene/router
import awene/web
import mist
import wisp
import wisp/wisp_mist
import dream_ets/config

pub fn main() -> Nil {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(table) =
    config.new("secrets")
    |> config.key_string()
    |> config.value_string()
    |> config.table_type(config.table_type_set())
    |> config.create()

  let context = web.Context(db: table)

  let handler = router.handle_request(_, context)
  
  let assert Ok(_) =
    handler
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}
