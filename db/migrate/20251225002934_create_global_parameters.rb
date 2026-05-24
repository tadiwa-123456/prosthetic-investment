class CreateGlobalParameters < ActiveRecord::Migration[8.1]
  def change
    create_table :global_parameters do |t|
      t.timestamps
      # Economic Parameters
      t.decimal :electricity_rate, default: 2.5, precision: 10, scale: 2
      t.decimal :labor_rate, default: 150.0, precision: 10, scale: 2
      t.decimal :annual_operating_hours, default: 2000, precision: 10, scale: 2

      # Gas & Consumables
      t.decimal :inert_gas_price, default: 25.0, precision: 10, scale: 2
      t.decimal :gas_consumption_per_hour, default: 0.5, precision: 10, scale: 3

      # Facility Costs
      t.decimal :annual_rent, default: 120_000.0, precision: 12, scale: 2
      t.decimal :annual_utilities, default: 60_000.0, precision: 12, scale: 2
      t.decimal :annual_admin, default: 80_000.0, precision: 12, scale: 2

      # Software/Digital
      t.decimal :annual_software_cost, default: 15_000.0, precision: 12, scale: 2
      t.decimal :annual_hpc_cost, default: 10_000.0, precision: 12, scale: 2

      # Maintenance
      t.decimal :preventive_maintenance_frequency, default: 4, precision: 10, scale: 0
      t.decimal :preventive_maintenance_cost, default: 5000.0, precision: 10, scale: 2
      t.decimal :corrective_maintenance_frequency, default: 2, precision: 10, scale: 0
      t.decimal :corrective_maintenance_cost, default: 12_000.0, precision: 10, scale: 2

      # Energy & Sustainability
      t.decimal :grid_emission_factor, default: 0.95, precision: 10, scale: 3
      t.decimal :waste_disposal_cost_per_kg, default: 2.5, precision: 10, scale: 2

      # Build Time Factors
      t.decimal :machine_power_consumption, default: 8.0, precision: 10, scale: 2
      t.decimal :setup_time_hours, default: 2.0, precision: 10, scale: 2
      t.decimal :post_processing_time_per_part, default: 1.5, precision: 10, scale: 2
    end
  end
end
