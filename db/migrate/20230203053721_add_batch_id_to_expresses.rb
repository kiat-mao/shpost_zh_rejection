class AddBatchIdToExpresses < ActiveRecord::Migration[6.0]
  def change
  	add_column :expresses, :batch_id, :integer
  end
end
