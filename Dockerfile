# Используем официальный образ Ruby
FROM ruby:3.2

# Устанавливаем зависимости системы
RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем Gemfile и Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Устанавливаем зависимости
RUN gem install bundler && bundle install

# Копируем всё приложение
COPY . .

# Пробрасываем порт
EXPOSE 3000

# Команда запуска Puma
CMD ["bundle", "exec", "puma", "-C", "puma.rb"]
