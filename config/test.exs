import Config

config :guesty,
  requester: Guesty.RequestMock,
  broadway_producer_module: Broadway.DummyProducer
