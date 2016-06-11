use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :hello, Hello.Endpoint,
  secret_key_base: "6JenSBdYGrh1+OjyCN19OwgbQi7hSDflXuL4d8c9YRkbZYhYKkYh83bmgBt2teZ/"

# Configure your database
config :hello, Hello.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "hello_prod",
  pool_size: 20
