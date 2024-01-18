class ChangeExpressNoToOrders < ActiveRecord::Migration[6.0]
  def change
  	change_column :orders, :express_no, :string, :unique => true
  end
end
