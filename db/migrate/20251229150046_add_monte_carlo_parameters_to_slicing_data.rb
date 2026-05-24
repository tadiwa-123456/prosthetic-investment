class AddMonteCarloParametersToSlicingData < ActiveRecord::Migration[8.1]
  def change
    # db/migrate/XXXXXX_add_monte_carlo_parameters_to_slicing_data.rb
    add_column :slicing_data, :cost_volatility, :decimal, precision: 5, scale: 4
    add_column :slicing_data, :revenue_volatility, :decimal, precision: 5, scale: 4
    add_column :slicing_data, :monte_carlo_iterations, :integer
  end
end
