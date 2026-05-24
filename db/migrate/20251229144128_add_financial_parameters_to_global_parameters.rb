class AddFinancialParametersToGlobalParameters < ActiveRecord::Migration[8.1]
  def change
    add_column :global_parameters, :price_per_part, :decimal, precision: 10, scale: 2, default: 1000.0
    add_column :global_parameters, :discount_rate, :decimal, precision: 5, scale: 4, default: 0.10
    add_column :global_parameters, :analysis_horizon_years, :integer, default: 5
    add_column :global_parameters, :upfront_investment, :decimal, precision: 15, scale: 2, default: 5_000_000.0
    add_column :global_parameters, :machine_utilization_rate, :decimal, precision: 3, scale: 2, default: 0.75
    add_column :global_parameters, :minimum_acceptable_return, :decimal, precision: 5, scale: 2, default: 15.0
  end
end
