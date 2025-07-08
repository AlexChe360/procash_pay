require "roda"
require "json"
require "sequel"
require "dotenv/load"
require "net/http"
require "uri"
require_relative "./handlers/whatsapp_handler"

# Инициализация SQLite
DB = Sequel.sqlite("procash.db")

# Таблица payments
DB.create_table? :payments do
  primary_key :id
  String :order_guid
  Integer :chat_id
  String :receipt_url
  DateTime :paid_at
end

class Payment < Sequel::Model(:payments)
end

class App < Roda
  plugin :json
  plugin :render
  plugin :request_headers
  plugin :static, ["/static"], root: File.expand_path(".")

  route do |r|
    r.root do
      response["Content-Type"] = "text/html"
      begin
        File.read("static/index.html")
      rescue => e
        response.status = 500
        "Ошибка загрузки index.html: #{e.message}"
      end
    end

    r.get "privacy" do
      view("privacy")
    end

    # Callback от FreedomPay
    r.post "callback" do
      begin
        payload = JSON.parse(r.body.read)

        required = %w[order_guid receipt_url chat_id]
        unless required.all? { |k| payload[k] && !payload[k].to_s.strip.empty? }
          response.status = 400
          next({ error: "Missing required fields" }.to_json)
        end

        # Сохраняем в SQLite
        Payment.create(
          order_guid: payload["order_guid"],
          receipt_url: payload["receipt_url"],
          chat_id: payload["chat_id"],
          paid_at: Time.now
        )

        # Уведомляем пользователя в Telegram
        send_thank_you_message(
          chat_id: payload["chat_id"],
          order_guid: payload["order_guid"],
          receipt_url: payload["receipt_url"]
        )

        { status: "ok", message: "Оплата принята" }.to_json

      rescue => e
        response.status = 500
        { error: "Callback failed: #{e.message}" }.to_json
      end
    end

    r.on "whatsapp" do
      
      r.get do
        if r.params["hub.mode"] == "subscribe" || r.params["hub.verify_token"] == ENV["WHATSAPP_VERIFY_TOKEN"]
          r.params["hub.challenge"]
        else
          response.status = 403
          "Forbidden"
        end
      end

     r.post do
  begin
    request_body = request.body.read
    payload = JSON.parse(request_body)

    # Логируем весь входящий payload для отладки
    puts "📥 WhatsApp payload:"
    puts JSON.pretty_generate(payload)

    messages = payload.dig("entry", 0, "changes", 0, "value", "messages")

    if messages.nil? || messages.empty?
      response.status = 400
      puts "⚠️ Нет сообщений в payload"
      next "❌ Нет сообщений"
    end

    from = messages.dig(0, "from")
    text = messages.dig(0, "text", "body")

    if from && text
      puts "👤 Получено сообщение от #{from}: #{text.inspect}"
      result = WhatsappHandler.process_message(text, from)
      result ? "✅ OK" : "⚠️ Обработка не удалась"
    else
      response.status = 400
      puts "❌ Не удалось найти from или text"
      "❌ Неверная структура сообщения"
    end

  rescue JSON::ParserError => e
    response.status = 400
    puts "❌ Ошибка парсинга JSON: #{e.message}"
    "❌ Некорректный JSON"

  rescue => e
    response.status = 500
    puts "❌ Внутренняя ошибка сервера: #{e.message}"
    "❌ Ошибка обработки сообщения"
  end
end

    end
  end

  # Отправка сообщения в Telegram
  def send_thank_you_message(chat_id:, order_guid:, receipt_url:)
    token = ENV["TELEGRAM_BOT_TOKEN"]
    uri = URI("https://api.telegram.org/bot#{token}/sendMessage")

    message = <<~TEXT
      ✅ Спасибо за оплату заказа №#{order_guid}!
      💳 Ваш чек: #{receipt_url}
    TEXT

    res = Net::HTTP.post_form(uri, {
      "chat_id" => chat_id,
      "text"    => message.strip
    })

    puts "📤 Telegram уведомление: #{res.body}"
  end
end
