# puma.rb
bind "tcp://192.168.0.102:3000"
workers 1
threads 1, 5
