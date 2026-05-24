class UpdateSlicingDataModel < ActiveRecord::Migration[8.1]
  def change
    add_reference :slicing_data, :machine, foreign_key: true
    add_reference :slicing_data, :material, foreign_key: true

    # Add production parameters
    add_column :slicing_data, :parts_per_build, :integer, default: 1
    add_column :slicing_data, :material_utilization, :decimal, default: 0.6

    # Add calculated fields
    add_column :slicing_data, :part_mass, :decimal
    add_column :slicing_data, :total_powder_mass, :decimal
    add_column :slicing_data, :build_time_hours, :decimal
  end
end
