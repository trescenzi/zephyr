import app/data
import app/db
import app/middleware
import gleam/dynamic
import gleam/io
import gleam/list
import gleam/otp/actor.{type StartError}
import gleam/result.{map_error}
import mist
import wisp.{type Request, type Response}
import wisp/wisp_mist

pub fn router(req: Request, ctx: middleware.Context) -> Response {
  wisp.path_segments(req)
  |> list.map(io.debug)
  wisp.get_query(req)
  |> list.map(io.debug)
  case wisp.path_segments(req) {
    //[] -> home(req, ctx)
    //["add", ..] -> add(req, ctx)
    //["oauth", ..] -> oauth(req, ctx)
    //["save_notifications", ..] -> save_notifications(req, ctx)
    //["send_message", id] -> send_message_test(req, ctx, id)
    ["data", "report"] -> data.handle(req, ctx)

    _ -> wisp.not_found()
  }
}

pub fn handle_request(req: Request, ctx: middleware.Context) -> Response {
  middleware.middleware(req, ctx, router)
}

pub fn init(password: String) {
  let db = db.connect()
  let ctx = middleware.Context(password, db)
  let handler = handle_request(_, ctx)

  wisp_mist.handler(handler, password)
  |> mist.new()
  |> mist.bind("0.0.0.0")
  |> mist.port(2469)
  |> mist.start_http()
  |> map_error(to_starterror)
}

fn to_starterror(glisten_error) -> StartError {
  actor.InitCrashed(dynamic.from(glisten_error))
}
