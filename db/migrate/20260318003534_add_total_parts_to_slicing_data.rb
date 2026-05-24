class AddTotalPartsToSlicingData < ActiveRecord::Migration[8.1]
  def change
    add_column :slicing_data, :number_of_parts, :integer, default: 1
  end
end
