import pinkdf2
import gleam/string

pub fn hash(password: String) -> Result(String, String) {
  let salt = pinkdf2.get_salt()
  hash_(password, salt)
}

fn hash_(password: String, salt: String) -> Result(String, String) {
  let result = pinkdf2.with_defaults(password, salt)

  case result {
    Ok(pinkdf2.Pbkdf2Keys(_, base64)) -> Ok(base64 <> "." <> salt)
    Error(_) -> Error("Password hash failed")
  }
}

pub fn verify(password: String, hashline: String) -> Bool {
  case string.split(hashline, ".") {
    [_, salt] -> {
      let result = hash_(password, salt)
      case result {
        Ok(hash) -> hashline == hash
        Error(_) -> False
      }
    }
    _ -> False
  }
}
