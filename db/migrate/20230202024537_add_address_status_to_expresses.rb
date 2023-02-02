class AddAddressStatusToExpresses < ActiveRecord::Migration[6.0]
  def change
        add_column :expresses, :address_status, :string
  end
end
