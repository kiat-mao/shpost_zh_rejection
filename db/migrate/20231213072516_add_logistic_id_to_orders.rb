class AddLogisticIdToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :logistic_id, :string
  end
end
