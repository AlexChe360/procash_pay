require "telegram/bot"
require "dotenv/load"
require "uri"

require_relative "../services/r_keeper_service"
require_relative "../services/freedom_service"

Telegram::Bot::Client.run(ENV["TELEGRAM_BOT_TOKEN"]) do |bot|
  puts "🤖 Telegram бот запущен"

  bot.listen do |message|
    next unless message.text&.start_with?("/start")

    begin
      payload = URI.decode_www_form(message.text.sub("/start", "").strip).to_h
      restaurant_id = payload["restaurantId"].to_i
      table_number  = payload["tableNumber"]

      table_code = RKeeperService.get_table_code(restaurant_id, table_number)
      order_guid, waiter_id = RKeeperService.get_order_info(restaurant_id, table_code)
      order = RKeeperService.get_order_details(restaurant_id, order_guid)
      waiter_name = RKeeperService.get_waiter_name(restaurant_id, waiter_id)

      text = "💺 Стол №#{table_number}\n"
      text += "🧑‍🍳 Официант: #{waiter_name}\n"
      text += "🍽 Заказ:\n"
      order[:items].each do |item|
        text += "- #{item[:name]} #{item[:quantity]} = #{item[:amount]}₸\n"
      end
      text += "🧾 Итого: #{order[:total_sum]}₸"

      # Генерация платёжной ссылки
      payment_result = FreedomService.generate_url(
        amount: order[:total_sum],
        description: "Счёт за стол #{table_number} в заведении #{restaurant_id}",
        user_id: "telegram_#{message.chat.id}"
      )

      if payment_result[:redirect_url]
        pay_url = payment_result[:redirect_url]

        kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: [
            [Telegram::Bot::Types::InlineKeyboardButton.new(text: "💳 Оплатить", url: pay_url)]
          ]
        )

        bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: kb)
      else
        bot.api.send_message(chat_id: message.chat.id, text: "❌ Не удалось сформировать платёжную ссылку")
      end

    rescue => e
      puts "Ошибка Telegram бота: #{e.message}"
      bot.api.send_message(chat_id: message.chat.id, text: "❌ Произошла ошибка, попробуйте позже")
    end
  end
end
