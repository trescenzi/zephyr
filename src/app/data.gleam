import app/middleware
import gleam/dict
import gleam/dynamic
import gleam/float
import gleam/http.{Post}
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo
import gleam/result
import gleam/string
import wisp.{type Request, type Response}

pub type Condition {
  Condition(
    location: String,
    temp: Option(Float),
    humidity: Option(Float),
    pressure: Option(Float),
    co2: Option(Float),
    pm2_5: Option(Float),
    pm10: Option(Float),
    wind: Option(Float),
    wind_gust: Option(Float),
    wind_direction: Option(Float),
    solar: Option(Float),
    uv_index: Option(Float),
    rain: Option(Float),
  )
}

fn to_float(str: String) -> Float {
  result.unwrap(float.parse(str), 0.0)
}

fn parse_pressure(pressure: String) -> Float {
  to_float(pressure) *. 33.8639
}

fn parse_temp(temp: String, temp_unit: String) -> Float {
  case temp_unit {
    "c" -> to_float(temp)
    "f" -> { to_float(temp) -. 32.0 } /. 1.8
    _ -> 0.0
  }
}

fn parse_wind(speed: String, wind_unit: String) -> Float {
  case wind_unit {
    "mph" -> to_float(speed)
    "knots" -> to_float(speed) *. 0.86897624
    // don't actually know what m/s comes in as
    "mps" -> to_float(speed) *. 2.23693629
    "m" -> to_float(speed) *. 2.23693629
    _ -> 0.0
  }
}

fn insert_condition(condition: Condition, db: pgo.Connection) {
  let sql =
    "
    insert into conditions
      (time, location, temperature, humidity, pressure, co2, pm2_5, pm10, wind, wind_gust, wind_direction, solar, uv_index)
    values (NOW(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) returning location;
  "

  let float = pgo.nullable(pgo.float, _)

  let response =
    pgo.execute(
      sql,
      db,
      [
        pgo.text(condition.location),
        float(condition.temp),
        float(condition.humidity),
        float(condition.pressure),
        float(condition.co2),
        float(condition.pm2_5),
        float(condition.pm10),
        float(condition.wind),
        float(condition.wind_gust),
        float(condition.wind_direction),
        float(condition.solar),
        float(condition.uv_index),
      ],
      dynamic.element(0, dynamic.string),
    )

  case response {
    Ok(r) -> {
      io.debug(r)
      io.debug("Success")
    }
    Error(e) -> {
      io.debug(e)
      io.debug("Error")
    }
  }
}

pub fn handle(req: Request, ctx: middleware.Context) -> Response {
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_string_body(req)

  io.debug(body)

  let split_pair = string.split(_, "=")

  // "baromabsin=30.404", "baromrelin=30.404", "humidityin=54", "tempinf=67.82"
  // tempf=69.08&humidity=48&winddir=102&windspeedmph=4.03&windgustmph=5.37&maxdailygust=7.16&solarradiation=540.73&uv=5&rrain_piezo=0.000&erain_piezo=0.000&hrain_piezo=0.000&drain_piezo=0.000&wrain_piezo=0.000&mrain_piezo=0.000&yrain_piezo=0.000&srain_piezo=0
  // "co2_batt=6", "co2_24h=877", "co2=977", "pm10_24h_co2=2.4", "pm10_co2=1.6", "pm25_24h_co2=1.7", "pm25_co2=1.2", "humi_co2=59", "tf_co2=66.92"
  let conditions =
    string.split(body, "&")
    |> list.group(fn(pair) {
      let assert [key, ..] = split_pair(pair)
      case string.split(key, "_") {
        ["co2", ..] | [_, "co2"] | [_, _, "co2"] -> "CO2X4865"
        ["baromabsin"] | ["baromrelin"] | ["humidityin"] | ["tempinf"] ->
          "INSIDE:01"
        ["temp" <> _temp_unit]
        | ["humidity"]
        | ["winddir"]
        | ["windspeed" <> _wind_unit]
        | ["windgust" <> _wind_gust_unit]
        | ["solar" <> _solar]
        | ["uv"] -> "OUTSIDE:WS:90"
        _ -> "info"
      }
    })
    |> dict.map_values(fn(key, values) {
      list.fold(
        values,
        from: Condition(
          location: key,
          temp: None,
          humidity: None,
          pressure: None,
          co2: None,
          pm2_5: None,
          pm10: None,
          wind: None,
          wind_gust: None,
          wind_direction: None,
          solar: None,
          uv_index: None,
          rain: None,
        ),
        with: fn(cond, pair) {
          let assert [key, value] = split_pair(pair)
          case key {
            // we don't care about the 24hr averages we can compute that ourselves
            "pm10_24h" <> _ | "pm25_24h" <> _ | "co2_24h" -> cond

            // pressure, store absolute
            "baromabsin" ->
              Condition(..cond, pressure: Some(parse_pressure(value)))

            // temperature in f, convert to c
            "tempin" <> temp_unit | "temp" <> temp_unit | "t" <> temp_unit ->
              Condition(..cond, temp: Some(parse_temp(value, temp_unit)))

            "winddir" ->
              Condition(
                ..cond,
                // 0 is north
                wind_direction: Some(to_float(value)),
              )
            "windspeed" <> wind_unit ->
              Condition(..cond, wind: Some(parse_wind(value, wind_unit)))
            "windgust" <> wind_unit ->
              Condition(..cond, wind_gust: Some(parse_wind(value, wind_unit)))

            "solar" <> _ -> Condition(..cond, solar: Some(to_float(value)))

            "uv" -> Condition(..cond, uv_index: Some(to_float(value)))

            // humidity, pm, and co2
            "humi" <> _ -> Condition(..cond, humidity: Some(to_float(value)))
            "pm10_co2" <> _ -> Condition(..cond, pm10: Some(to_float(value)))
            "pm25_co2" <> _ -> Condition(..cond, pm2_5: Some(to_float(value)))
            "co2" <> _ -> Condition(..cond, co2: Some(to_float(value)))

            _ -> cond
          }
        },
      )
    })
    |> dict.values
    |> list.filter(fn(cond) { cond.location != "info" })
    |> list.map(insert_condition(_, ctx.db))

  io.debug(conditions)

  wisp.ok()
}
