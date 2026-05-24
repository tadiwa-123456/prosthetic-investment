# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_17_020000) do
  create_table "cost_line_items", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_per_build", default: true
    t.string "name", null: false
    t.integer "position"
    t.decimal "quantity", precision: 15, scale: 4, default: "1.0", null: false
    t.integer "slicing_datum_id", null: false
    t.decimal "total_cost", precision: 15, scale: 2
    t.decimal "unit_cost", precision: 15, scale: 2, null: false
    t.string "unit_type"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_cost_line_items_on_category"
    t.index ["slicing_datum_id", "category"], name: "index_cost_line_items_on_slicing_datum_id_and_category"
    t.index ["slicing_datum_id"], name: "index_cost_line_items_on_slicing_datum_id"
  end

  create_table "global_parameters", force: :cascade do |t|
    t.integer "analysis_horizon_years", default: 5
    t.decimal "annual_admin", precision: 12, scale: 2, default: "80000.0"
    t.decimal "annual_hpc_cost", precision: 12, scale: 2, default: "10000.0"
    t.decimal "annual_operating_hours", precision: 10, scale: 2, default: "2000.0"
    t.decimal "annual_rent", precision: 12, scale: 2, default: "120000.0"
    t.decimal "annual_software_cost", precision: 12, scale: 2, default: "15000.0"
    t.decimal "annual_utilities", precision: 12, scale: 2, default: "60000.0"
    t.decimal "corrective_maintenance_cost", precision: 10, scale: 2, default: "12000.0"
    t.decimal "corrective_maintenance_frequency", precision: 10, default: "2"
    t.decimal "cost_volatility", precision: 5, scale: 4, default: "0.1"
    t.datetime "created_at", null: false
    t.decimal "discount_rate", precision: 5, scale: 4, default: "0.1"
    t.decimal "electricity_rate", precision: 10, scale: 2, default: "2.5"
    t.decimal "gas_consumption_per_hour", precision: 10, scale: 3, default: "0.5"
    t.decimal "grid_emission_factor", precision: 10, scale: 3, default: "0.95"
    t.decimal "inert_gas_price", precision: 10, scale: 2, default: "25.0"
    t.decimal "labor_rate", precision: 10, scale: 2, default: "150.0"
    t.decimal "machine_power_consumption", precision: 10, scale: 2, default: "8.0"
    t.decimal "machine_utilization_rate", precision: 3, scale: 2, default: "0.75"
    t.decimal "minimum_acceptable_return", precision: 5, scale: 2, default: "15.0"
    t.integer "monte_carlo_iterations", default: 10000
    t.decimal "post_processing_time_per_part", precision: 10, scale: 2, default: "1.5"
    t.decimal "preventive_maintenance_cost", precision: 10, scale: 2, default: "5000.0"
    t.decimal "preventive_maintenance_frequency", precision: 10, default: "4"
    t.decimal "price_per_part", precision: 10, scale: 2, default: "1000.0"
    t.decimal "revenue_volatility", precision: 5, scale: 4, default: "0.1"
    t.decimal "setup_time_hours", precision: 10, scale: 2, default: "2.0"
    t.datetime "updated_at", null: false
    t.decimal "upfront_investment", precision: 15, scale: 2, default: "5000000.0"
    t.decimal "waste_disposal_cost_per_kg", precision: 10, scale: 2, default: "2.5"
  end

  create_table "machines", force: :cascade do |t|
    t.decimal "annual_maintenance_cost"
    t.decimal "build_volume_x"
    t.decimal "build_volume_y"
    t.decimal "build_volume_z"
    t.datetime "created_at", null: false
    t.decimal "laser_power"
    t.integer "lifespan_years"
    t.string "model_number"
    t.string "name"
    t.decimal "purchase_price"
    t.decimal "scan_speed"
    t.datetime "updated_at", null: false
  end

  create_table "materials", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.decimal "density"
    t.decimal "embodied_carbon"
    t.string "name"
    t.decimal "raw_material_price"
    t.decimal "recycling_efficiency"
    t.datetime "updated_at", null: false
  end

  create_table "slicing_data", force: :cascade do |t|
    t.integer "analysis_horizon_years"
    t.decimal "annual_admin", precision: 12, scale: 2
    t.decimal "annual_hpc_cost", precision: 12, scale: 2
    t.decimal "annual_operating_hours", precision: 10, scale: 2
    t.decimal "annual_rent", precision: 12, scale: 2
    t.decimal "annual_software_cost", precision: 12, scale: 2
    t.decimal "annual_utilities", precision: 12, scale: 2
    t.decimal "build_time_hours"
    t.decimal "corrective_maintenance_cost", precision: 10, scale: 2, default: "12000.0"
    t.decimal "corrective_maintenance_frequency", precision: 10, default: "2"
    t.decimal "cost_volatility", precision: 5, scale: 4
    t.datetime "created_at", null: false
    t.string "csv_file"
    t.decimal "discount_rate", precision: 5, scale: 4
    t.decimal "electricity_rate", precision: 10, scale: 2
    t.decimal "gas_consumption_per_hour", precision: 10, scale: 3
    t.decimal "grid_emission_factor", precision: 10, scale: 3
    t.decimal "inert_gas_price", precision: 10, scale: 2
    t.decimal "labor_rate", precision: 10, scale: 2
    t.decimal "layer_thickness"
    t.integer "machine_id"
    t.decimal "machine_power_consumption", precision: 10, scale: 2
    t.decimal "machine_utilization_rate", precision: 3, scale: 2
    t.integer "material_id"
    t.decimal "material_utilization", default: "0.6"
    t.decimal "minimum_acceptable_return", precision: 5, scale: 2
    t.integer "monte_carlo_iterations"
    t.decimal "part_height"
    t.decimal "part_mass"
    t.string "part_name"
    t.decimal "part_volume"
    t.decimal "post_processing_time_per_part", precision: 10, scale: 2
    t.decimal "preventive_maintenance_cost", precision: 10, scale: 2, default: "5000.0"
    t.decimal "preventive_maintenance_frequency", precision: 10, default: "4"
    t.decimal "price_per_part", precision: 10, scale: 2
    t.decimal "revenue_volatility", precision: 5, scale: 4
    t.decimal "setup_time_hours", precision: 10, scale: 2
    t.decimal "support_volume"
    t.decimal "surface_area"
    t.integer "total_parts_produced", default: 1, null: false
    t.decimal "total_powder_mass"
    t.datetime "updated_at", null: false
    t.decimal "upfront_investment", precision: 15, scale: 2
    t.boolean "use_custom_parameters", default: false
    t.decimal "waste_disposal_cost_per_kg", precision: 10, scale: 2
    t.index ["machine_id"], name: "index_slicing_data_on_machine_id"
    t.index ["material_id"], name: "index_slicing_data_on_material_id"
  end

  add_foreign_key "cost_line_items", "slicing_data"
  add_foreign_key "slicing_data", "machines"
  add_foreign_key "slicing_data", "materials"
end
