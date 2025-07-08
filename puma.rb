# puma.rb
bind "tcp://localhost:3000"
workers 1
threads 1, 5
