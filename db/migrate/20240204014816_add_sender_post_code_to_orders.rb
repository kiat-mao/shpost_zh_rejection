class AddSenderPostCodeToOrders < ActiveRecord::Migration[6.0]
  def change
  	add_column :orders, :sender_postcode, :string
  end
end
