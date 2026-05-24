class AddBuildsPerYearToSlicingData < ActiveRecord::Migration[8.1]
  def change
    add_column :slicing_data, :builds_per_year, :integer, default: 1, null: false
  end
end
