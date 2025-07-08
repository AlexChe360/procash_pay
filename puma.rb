# puma.rb
port ENV.fetch("PORT") { 3000 }
bind "tcp://0.0.0.0:3000"
workers 0
threads 1, 5
environment ENV.fetch("RACK_ENV") { "development" }

