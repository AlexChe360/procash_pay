require_relative "../services/freedom_service"
require_relative "../services/r_keeper_service"
require_relative "../services/whatsapp_service"

class WhatsappHandler
  def self.process_message(message, from)
    meta = message[/meta=(\d+)-(\d+)/, 1..2]
    restaurant_id = meta[0]
    table_number  = meta[1]

    return false unless restaurant_id && table_number

    table_code = RKeeperService.get_table_code(restaurant_id.to_i, table_number)
    order, waiter_id = RKeeperService.get_order_info(restaurant_id.to_i, table_code)
    waiter_name = RKeeperService.get_waiter_name(restaurant_id.to_i, waiter_id)

    text = "Добро пожаловать в сервис быстрой оплаты *PROCASH*\n\n"
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
  end
end
