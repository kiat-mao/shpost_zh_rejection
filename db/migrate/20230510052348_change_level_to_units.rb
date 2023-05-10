class ChangeLevelToUnits < ActiveRecord::Migration[6.0]
  def change
  	rename_column :units, :level, :unit_level
  end
end
