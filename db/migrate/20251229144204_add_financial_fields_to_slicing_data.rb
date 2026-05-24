class AddFinancialFieldsToSlicingData < ActiveRecord::Migration[8.1]
  def change
    add_column :slicing_data, :price_per_part, :decimal, precision: 10, scale: 2
    add_column :slicing_data, :discount_rate, :decimal, precision: 5, scale: 4
    add_column :slicing_data, :analysis_horizon_years, :integer
    add_column :slicing_data, :upfront_investment, :decimal, precision: 15, scale: 2
    add_column :slicing_data, :machine_utilization_rate, :decimal, precision: 3, scale: 2
    add_column :slicing_data, :minimum_acceptable_return, :decimal, precision: 5, scale: 2
  end
end
