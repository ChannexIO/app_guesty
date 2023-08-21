import Config

config :message_queue,
  connection: [host: "rabbitmq", username: "guest", password: "guest"]
