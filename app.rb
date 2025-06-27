require "roda"
require "json"
require "sequel"
require "dotenv/load"
require "net/http"
require "uri"

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
  plugin :request_headers
  plugin :static, ["/static"], root: File.expand_path(".")

  route do |r|
    # HTML для выбора мессенджера
    r.root do
      File.read("static/index.html")
    end

    # Callback от FreedomPay
    r.post "callback" do
      begin
        payload = JSON.parse(r.body.read)

        required = %w[order_guid receipt_url chat_id]
        unless required.all? { |k| payload[k] && !payload[k].to_s.strip.empty? }
          response.status = 400
          next { error: "Missing required fields" }
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

        { status: "ok", message: "Оплата принята" }

      rescue => e
        response.status = 500
        { error: "Callback failed: #{e.message}" }
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
