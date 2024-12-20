import Config

config :nostrum,
  token: System.fetch_env!("BOT_TOKEN"),
  gateway_intents: :all
