class AddOperatorsToExpresses < ActiveRecord::Migration[6.0]
  def change
  	add_column :expresses, :operator1, :integer
  	add_column :expresses, :operator2, :integer
  end
end
