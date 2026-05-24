class AddMonteCarloParametersToGlobalParameters < ActiveRecord::Migration[8.1]
  def change
    add_column :global_parameters, :cost_volatility, :decimal, precision: 5, scale: 4, default: 0.10
    add_column :global_parameters, :revenue_volatility, :decimal, precision: 5, scale: 4, default: 0.10
    add_column :global_parameters, :monte_carlo_iterations, :integer, default: 10_000
  end
end
