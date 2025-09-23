class AddColumnsToOrders < ActiveRecord::Migration[6.0]
  def change
  	add_column :orders, :bank_name, :string
  	add_column :orders, :category, :string
  end
end
