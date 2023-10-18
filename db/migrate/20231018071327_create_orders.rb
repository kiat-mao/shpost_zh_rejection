class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders do |t|
      t.string   :express_no, index: true

      t.string   :sender_province
      t.string   :sender_city
      t.string   :sender_district
      t.string   :sender_addr
      t.string   :sender_name
      t.string   :sender_phone
      t.string   :receiver_province
      t.string   :receiver_city
      t.string   :receiver_district
      t.string   :receiver_postcode
      t.string   :receiver_addr
      t.string   :receiver_name
      t.string   :receiver_phone

      t.string   :status
      t.string   :address_status

      # t.string   :route_code

      t.timestamps
    end
  end
end
