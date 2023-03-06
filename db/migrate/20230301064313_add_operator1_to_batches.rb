class AddOperator1ToBatches < ActiveRecord::Migration[6.0]
  def change
  	add_column :batches, :operator1, :integer
  end
end
