import app/web
import gleam/erlang/process
import gleam/io

pub fn main() {
  io.println("Hello from weather_gateway!")
  let assert Ok(_) = web.init("test")
  process.sleep_forever()
}
