import Config
config :iex, default_prompt: ">>xilapa>>"
config :kv, :routing_table, [{?a..?z, node()}]

## in production set routing table with all expected nodes
if config_env() == :prod do
  config :kv, :routing_table, [
    {?a..?m, :"foo@computer-name"},
    {?n..?z, :"bar@computer-name"}
  ]
end
