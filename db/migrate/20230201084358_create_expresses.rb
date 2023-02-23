class CreateExpresses < ActiveRecord::Migration[6.0]
  def change
    create_table :expresses do |t|
      t.string   :express_no, index: true
      t.datetime :scaned_at

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

      t.string   :new_express_no, index: true
      t.string   :route_code



      t.boolean  :anomaly, default: false
      t.string   :anomaly_desc

      t.boolean  :removed, default: false

      t.string   :deal_require
      t.string   :deal_result
      t.string   :deal_desc


      t.timestamps
    end
  end
end
