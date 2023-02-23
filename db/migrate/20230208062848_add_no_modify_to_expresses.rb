class AddNoModifyToExpresses < ActiveRecord::Migration[6.0]
  def change
  	add_column :expresses, :no_modify, :boolean, :default => false
  end
end
