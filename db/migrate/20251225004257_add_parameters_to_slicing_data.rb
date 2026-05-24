class AddParametersToSlicingData < ActiveRecord::Migration[8.1]
  def change
    # Economic Parameters
    add_column :slicing_data, :electricity_rate, :decimal, precision: 10, scale: 2
    add_column :slicing_data, :labor_rate, :decimal, precision: 10, scale: 2
    add_column :slicing_data, :annual_operating_hours, :decimal, precision: 10, scale: 2

    # Gas & Consumables
    add_column :slicing_data, :inert_gas_price, :decimal, precision: 10, scale: 2
    add_column :slicing_data, :gas_consumption_per_hour, :decimal, precision: 10, scale: 3

    # Facility Costs
    add_column :slicing_data, :annual_rent, :decimal, precision: 12, scale: 2
    add_column :slicing_data, :annual_utilities, :decimal, precision: 12, scale: 2
    add_column :slicing_data, :annual_admin, :decimal, precision: 12, scale: 2

    # Software/Digital
    add_column :slicing_data, :annual_software_cost, :decimal, precision: 12, scale: 2
    add_column :slicing_data, :annual_hpc_cost, :decimal, precision: 12, scale: 2

    # Energy & Sustainability
    add_column :slicing_data, :grid_emission_factor, :decimal, precision: 10, scale: 3
    add_column :slicing_data, :waste_disposal_cost_per_kg, :decimal, precision: 10, scale: 2

    # Build Time Factors
    add_column :slicing_data, :machine_power_consumption, :decimal, precision: 10, scale: 2
    add_column :slicing_data, :setup_time_hours, :decimal, precision: 10, scale: 2
    add_column :slicing_data, :post_processing_time_per_part, :decimal, precision: 10, scale: 2

    # Flag to track if using custom parameters
    add_column :slicing_data, :use_custom_parameters, :boolean, default: false
  end
end
