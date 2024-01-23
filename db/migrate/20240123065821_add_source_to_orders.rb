class AddSourceToOrders < ActiveRecord::Migration[6.0]
  def change
  	add_column :orders, :source, :string
  end
end
