class AddRouteCodeToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :route_code, :string
  end
end
