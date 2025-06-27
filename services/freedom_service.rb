require "securerandom"
require "digest"
require "net/http"
require "uri"
require "nakogiri"

class FreedomService
    def self.generate_url(amount:, description:)
        test_mode = ENV["PAYMENT_TEST_MODE"] == "true"

        merchant_id = test_mode ? ENV["TEST_MERCHANT_ID"] : ENV["MERCHANT_ID"]
        secret_key = test_mode ? ENV["TEST_PAYMENT_SECRET_KEY"] : ENV ["PAYMENT_SECRET_KEY"]
        user_id = ENV["USER_ID"]

        raise "Missing merchant_id or secret_key" unless merchant_id && secret_key

        request = {
            "pg_order_id"       => "%05d" % rand(100000),
            "pg_merchant_id"    => merchant_id,
            "pg_amount"         => amount.to_s,
            "pg_description"    => description,
            "pg_salt"           => SecureRandom.hex(8),
            "pg_payment_route"  => "frame",
            "pg_user_id"        => user_id,
        }

        # Подпись
        request["pg_sig"] = generate_signature(request, secret_key)

        # Отправка
        response = send_request(request)

        # Парсинг ответа
        parse_response(response)
    end

    private 

    def self.generate_signature(params, secret_key)
        order = %w[
            pg_amount
            pg_description
            pg_merchant_id
            pg_order_id
            pg_payment_route
            pg_salt
            pg_user_id
        ]

        data = ["init_payment.php"] + order.map { |k| params[k].to_s } + [secret_key]
        Digest::MD5.hexdigest(data.join(";"))
    end

    def send_request(request_params)
        uri = URI.parse(ENV["PAYMENT_URL"])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"

        req = Net::HTTP::Post.new(uri)
        req.set_from_data(request_params)

        puts "[FreedomPay] Send request:"
        puts request_params.inspect

        http.request(req)
    end

    def self.parse_response(response)
        if response.is_a?(Net::HTTPSuccess)
            doc = Nokogiri::XML(response.body)
            {
                status: doc.at("pg_status")&.text,
                payment_id: doc.at("pg_payment_id")&.text,
                redirect_url: doc.at("pg_redirect_url")&.text,
                sig: doc.at("pg_sig")&.text
            }
        else
            { error: "#{response.code} - #{response.message}" }
        end    
    end
end