require "http"
require "json"

class RKeeperService
    ENDPOINT = "https://ws.ucs.ru/wsserverlp/api/v2/aggregators/Create"
    TOKEN = ENV["RKEEPER_TOKEN"]

    def self.post(task_type, params)
        HTTP.headers(
            "Content-Type" => "application/json",
            "AggregatorAuthentication" => "Token #{TOKEN}"
        ).post(ENDPOINT, json: { taskType: task_type, params: params }).parse
    end

    def self.get_table_code(restaurant_id, table_number) 
        response = post("GetTableList", 
            { sync: { 
                objectId: restaurant_id, 
                timeout: 120 
            } 
        })
        table = response["tables"].find { |t| t["externalNumber"] == table_number }
        raise "Table not found" unless table
        table["code"]
    end

    def self.get_order_info(restaurant_id, table_code)
        response = post("GetOrderList", {
            sync: {
                objectId: restaurant_id,
                timeout: 120
            },
            tableCode: table_code,
            withClosed: false
        })

        raise "No open orders" if response["orders"].empty?

        order_guid = response["orders"][0]["guid"]
        waiter_id = response["orders"][0]["waiterId"]

        [order_guid, waiter_id]
    end

    def self.get_order_details(restaurant_id, order_guid)
        response = post("GetOrder", {
            sync: {
                objectId: restaurant_id,
                timeout: 120
            },
            orderGuid: order_guid
        })
        {
            items: response["items"].map do |item|
                {
                    name: item["name"],
                    quantity: item["quantity"],
                    amount: item["amount"]
                }
            end,
            total_sum: response["totalSum"]
        }
    end

    def self.get_waiter_name(restaurant_id, waiter_id) 
        response = post("GetEmployees", {
            sync: {
                objectId: restaurant_id,
                timeout: 120
            }
        })

        waiter = response["employees"].find { |e| e["id"] == waiter_id }
        waiter ? waiter["name"] : "Unknown"
    end
end