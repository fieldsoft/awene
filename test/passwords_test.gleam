import awene/passwords

pub fn hash_test() -> Nil {
  let assert Ok(_) = passwords.hash("bibboy")
  Nil
}

pub fn verify_test() -> Nil {
  let assert Ok(hash) = passwords.hash("bibboy")
  assert passwords.verify("bibboy", hash)
  Nil
}
