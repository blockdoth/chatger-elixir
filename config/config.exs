import Config

config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:module],
  level: :debug

config :chatger,
  db_create_sql: "lib/database/create.sql",
  db_populate_sql: "lib/database/populate.sql",
  db_path: "data/penger.db"
