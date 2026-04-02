import gleam/bit_array.{base64_encode}
import gleam/http/request.{type Request, prepend_header}
import gleam/http/response.{type Response}
import gleam/httpc.{type HttpError}

/// Atempts basic auth to the CouchDB _session database and returns the result. On success, a UserCtx object can be inspected to ensure that the authorized user had the correct roles.
pub fn verify_auth(
  username: String,
  password: String,
  url: String,
) -> Result(Response(String), HttpError) {
  let assert Ok(base_req) = request.to(url <> "/_session")

  let credentials : String = username <> ":" <> password
  
  let creds: String =
    credentials
    |> bit_array.from_string()
    |> base64_encode(False)

  let req: Request(String) =
    base_req
    |> prepend_header(
      "www-authenticate",
      "Basic realm=\"None\", charset=\"UTF-8\"",
    )
    |> prepend_header("authorization", "Basic " <> creds)

  httpc.send(req)
}
