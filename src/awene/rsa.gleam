import gleam/bit_array

@external(erlang, "rsa_ffi", "sign")
fn do_sign(message: BitArray, pem: BitArray) -> Result(BitArray, BitArray)

@external(erlang, "rsa_ffi", "verify")
fn do_verify(
  message: BitArray,
  signature: BitArray,
  pem: BitArray,
) -> Result(Bool, BitArray)

pub fn sign(message: BitArray, pem: BitArray) -> Result(BitArray, String) {
  case do_sign(message, pem) {
    Error(err) -> {
      case bit_array.to_string(err) {
        Ok(err) -> Error(err)
        Error(_) -> Error("Non-string error")
      }
    }
    Ok(x) -> Ok(x)
  }
}

pub fn verify(
  message: BitArray,
  signature: BitArray,
  pem: BitArray,
) -> Result(Bool, String) {
  case do_verify(message, signature, pem) {
    Error(err) -> {
      case bit_array.to_string(err) {
        Ok(err) -> Error(err)
        Error(_) -> Error("Non-string error")
      }
    }
    Ok(x) -> Ok(x)
  }
}
