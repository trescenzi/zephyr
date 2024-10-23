import gleam/erlang/os
import gleam/option.{Some}
import gleam/pgo

pub fn connect() {
  let assert Ok(host) = os.get_env("WPG_DB_HOST")
  let assert Ok(database) = os.get_env("WPG_DB_DB")
  let assert Ok(user) = os.get_env("WPG_DB_USER")
  let assert Ok(password) = os.get_env("WPG_DB_PASS")
  pgo.connect(
    pgo.Config(
      ..pgo.default_config(),
      user: user,
      password: Some(password),
      host: host,
      database: database,
    ),
  )
}
