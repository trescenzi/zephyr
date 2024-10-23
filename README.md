# Zephyr

A lightweight weather station UI built to display data and proxy it from your station to a database.

## Supported Weather Stations

Zephyr is indented to support EcoWitt components. Currently it has been tested with a GW2000 station and a WS90.

At some point it might be extended to support any WeatherUnderground style station.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Environment Variables

- WPG_DB_HOST: The host of your postgres db
- WPG_DB_DB: The name of the database
- WPG_DB_USER: The user to interface with the database with
- WPG_DB_PASS: Password of the user

Currently there's an assumption that you have a single table called `Conditions` which looks something like:
```
+----------------+--------------------------+-----------+
| Column         | Type                     | Modifiers |
|----------------+--------------------------+-----------|
| time           | timestamp with time zone |  not null |
| location       | text                     |  not null |
| temperature    | double precision         |           |
| humidity       | double precision         |           |
| pressure       | double precision         |           |
| co2            | double precision         |           |
| pm2_5          | double precision         |           |
| pm10           | double precision         |           |
| wind           | double precision         |           |
| wind_direction | double precision         |           |
| wind_gust      | double precision         |           |
| solar          | double precision         |           |
| uv_index       | double precision         |           |
+----------------+--------------------------+-----------+
```
