require "net/http"
require "json"

class WhatsappService
  ENDPOINT = "https://graph.facebook.com/v18.0/#{ENV['WHATSAPP_PHONE_ID']}/messages"

  def self.send_buttons(phone, table_number:, waiter_name:, items:, total:, pay_url:)
    uri = URI.parse(ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer #{ENV['WHATSAPP_API_TOKEN']}"
    }

    items_text = items.map { |i| "#{i[:name]} — #{i[:amount]} ₸" }.join("; ")

    payload = {
      messaging_product: "whatsapp",
      to: phone,
      type: "template",
      template: {
        name: "procash_ru",
        language: { code: "ru" },
        components: [
          {
            type: "body",
            parameters: [
              { type: "text", text: table_number.to_s }, # стол
              { type: "text", text: waiter_name }, # официант
              { type: "text", text: items_text }, # позиции
              { type: "text", text: "#{total} ₸" }  # сумма
            ]
          },
          {
            type: "button",
            sub_type: "url",
            index: 0,
            parameters: [
              { type: "text", text: pay_url }
            ]
          },
          {
            type: "button",
            sub_type: "url",
            index: 1,
            parameters: [
              { type: "text", text: pay_url }
            ]
          },
          {
            type: "button",
            sub_type: "url",
            index: 2,
            parameters: [
              { type: "text", text: pay_url }
            ]
          },
        ]
      }
    }

    req = Net::HTTP::Post.new(uri.path, headers)
    req.body = payload.to_json

    res = http.request(req)
    res.code == "200"
  end
end
