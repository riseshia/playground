use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :rumbl, Rumbl.Endpoint,
  secret_key_base: "bRFtGdHZ+IIyRJsxuPvmAyQcS4XxRSojRn5zNN2w9t4mtxD6lpcYTFE7JrQKo3yK"

# Configure your database
config :rumbl, Rumbl.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "rumbl_prod",
  pool_size: 20
