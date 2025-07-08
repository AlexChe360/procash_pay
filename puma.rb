# puma.rb
port ENV.fetch("PORT") { 3001 }
workers 0
threads 1, 5
environment ENV.fetch("RACK_ENV") { "production" }

