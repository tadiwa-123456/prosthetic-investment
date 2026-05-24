class RefactorThroughputToTotalPartsPerYear < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:slicing_data, :total_parts_produced)
      add_column :slicing_data, :total_parts_produced, :integer, default: 1, null: false
    end

    remove_column :slicing_data, :builds_per_year, :integer if column_exists?(:slicing_data, :builds_per_year)
    remove_column :slicing_data, :parts_per_build, :integer if column_exists?(:slicing_data, :parts_per_build)
    remove_column :slicing_data, :number_of_parts, :integer if column_exists?(:slicing_data, :number_of_parts)
  end
end