require "sequel"

DB = Sequel.sqlite("procash.db")
DB.create_table? :payments do
    primary_kye: id
    String   :order_guid
    Integer  :chat_id
    String   :receipt_url
    DateTime :paid_at
end

class Payment < Sequel::Model(:payments)
end


