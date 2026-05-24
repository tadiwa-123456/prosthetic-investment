# db/seeds.rb

# Clear existing data
Machine.find_each(&:destroy)
Material.find_each(&:destroy)
GlobalParameter.find_each(&:destroy)

puts "Creating global parameters..."

GlobalParameter.create!(
  electricity_rate: 2.5,
  labor_rate: 150.0,
  annual_operating_hours: 2000,
  inert_gas_price: 25.0,
  gas_consumption_per_hour: 0.5,
  annual_rent: 120_000.0,
  annual_utilities: 60_000.0,
  annual_admin: 80_000.0,
  annual_software_cost: 15_000.0,
  annual_hpc_cost: 10_000.0,
  preventive_maintenance_frequency: 4,
  preventive_maintenance_cost: 5000.0,
  corrective_maintenance_frequency: 2,
  corrective_maintenance_cost: 12_000.0,
  grid_emission_factor: 0.95,
  waste_disposal_cost_per_kg: 2.5,
  machine_power_consumption: 8.0,
  setup_time_hours: 2.0,
  post_processing_time_per_part: 1.5
)

puts "Created global parameters"

puts "Creating machines..."

Machine.create!([
                  {
                    name: "SLM 280",
                    model_number: "SLM280",
                    build_volume_x: 280.0,
                    build_volume_y: 280.0,
                    build_volume_z: 365.0,
                    laser_power: 400.0,
                    scan_speed: 7000.0,
                    purchase_price: 750_000.0,
                    lifespan_years: 7,
                    annual_maintenance_cost: 50_000.0
                  },
                  {
                    name: "SLM 500",
                    model_number: "SLM500",
                    build_volume_x: 500.0,
                    build_volume_y: 280.0,
                    build_volume_z: 365.0,
                    laser_power: 700.0,
                    scan_speed: 10_000.0,
                    purchase_price: 1_200_000.0,
                    lifespan_years: 7,
                    annual_maintenance_cost: 75_000.0
                  },
                  {
                    name: "EOS M290",
                    model_number: "M290",
                    build_volume_x: 250.0,
                    build_volume_y: 250.0,
                    build_volume_z: 325.0,
                    laser_power: 400.0,
                    scan_speed: 7000.0,
                    purchase_price: 800_000.0,
                    lifespan_years: 7,
                    annual_maintenance_cost: 55_000.0
                  }
                ])

puts "Created #{Machine.count} machines"

puts "Creating materials..."

Material.create!([
                   {
                     name: "Titanium Ti-6Al-4V",
                     code: "Ti-6Al-4V",
                     density: 4.43,
                     raw_material_price: 350.0,
                     embodied_carbon: 35.0,
                     recycling_efficiency: 0.90
                   },
                   {
                     name: "Aluminum AlSi10Mg",
                     code: "AlSi10Mg",
                     density: 2.67,
                     raw_material_price: 45.0,
                     embodied_carbon: 8.5,
                     recycling_efficiency: 0.92
                   },
                   {
                     name: "Stainless Steel 316L",
                     code: "316L",
                     density: 7.99,
                     raw_material_price: 85.0,
                     embodied_carbon: 6.2,
                     recycling_efficiency: 0.88
                   },
                   {
                     name: "Inconel 718",
                     code: "IN718",
                     density: 8.19,
                     raw_material_price: 280.0,
                     embodied_carbon: 42.0,
                     recycling_efficiency: 0.85
                   }
                 ])

puts "Created #{Material.count} materials"
puts "Seed data created successfully!"
