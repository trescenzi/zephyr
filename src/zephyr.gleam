import app/web
import gleam/io
import gleam/erlang/process

pub fn main() {
  io.println("Hello from weather_gateway!")
  let assert Ok(_) = web.init("test")
  process.sleep_forever()
}
