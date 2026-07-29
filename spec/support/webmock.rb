require "webmock/rspec"

# Cuprite drives a real Chrome over localhost; only external HTTP is stubbed.
WebMock.disable_net_connect!(allow_localhost: true)
