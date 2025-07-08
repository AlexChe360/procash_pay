require_relative "../services/freedom_service"
require_relative "../services/r_keeper_service"
require_relative "../services/whatsapp_service"

# services/whatsapp_handler.rb
class WhatsappHandler
  def self.process_message(text, from)
    puts "📨 Обработка сообщения от #{from}: #{text}"

    # Попробуем извлечь номер стола из текста
    table_match = text.match(/стол[ №]*([0-9]+)/i)
    table_number = table_match[1] if table_match

    unless table_number
      WhatsappService.send_text(from, "❌ Не удалось определить номер стола. Пожалуйста, укажите его, например: 'Стол 5'")
      return false
    end

    # ⚠️ Здесь ты можешь захардкодить restaurant_id, например:
    restaurant_id = ENV["DEFAULT_RESTAURANT_ID"] || "373510013"

    table_code = RKeeperService.get_table_code(restaurant_id.to_i, table_number)
    order, waiter_id = RKeeperService.get_order_info(restaurant_id.to_i, table_code)
    waiter_name = RKeeperService.get_waiter_name(restaurant_id.to_i, waiter_id)

    text = "Добро пожаловать в сервис *PROCASH*\n\n"
    text += "💺 Стол №: *#{table_number}*\n"
    text += "👨‍🍳 Официант: #{waiter_name}\n"
    text += "📋 Заказ: #{order[:items].map { |i| "#{i[:name]} — #{i[:amount]} ₸" }.join("; ")}\n"
    text += "🧾 Итого: *#{order[:total_sum]} ₸*"

    pay_result = FreedomService.generate_url(order[:total_sum], "💳 Счёт на стол №#{table_number}", from)
    pay_url = pay_result[:redirect_url]

    WhatsappService.send_buttons(
      from,
      table_number: table_number,
      waiter_name: waiter_name,
      items: order[:items],
      total: order[:total_sum],
      pay_url: pay_url
    )

    true
  rescue => e
    puts "❌ Ошибка в WhatsappHandler: #{e.message}"
    WhatsappService.send_text(from, "❌ Произошла ошибка. Попробуйте ещё раз или обратитесь к официанту.")
    false
  end
end

