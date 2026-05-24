# app/services/default_line_items_creator.rb
class DefaultLineItemsCreator
  attr_reader :slicing_data

  def initialize(slicing_data)
    @slicing_data = slicing_data
    @params = slicing_data.effective_parameters
    @machine = slicing_data.machine
    @material = slicing_data.material
  end

  def create
    create_labor_items
    create_consumable_items
    create_energy_items
    create_equipment_items
  end

  private

  def create_labor_items
    # Setup labor
    slicing_data.cost_line_items.create!(
      category: "labor",
      name: "Setup Labor",
      description: "Machine setup and preparation",
      unit_cost: @params.labor_rate,
      quantity: @params.setup_time_hours,
      unit_type: "hours",
      is_per_build: true,
      position: 1
    )

    # Build supervision
    slicing_data.cost_line_items.create!(
      category: "labor",
      name: "Build Supervision",
      description: "Operator supervision during build",
      unit_cost: @params.labor_rate,
      quantity: slicing_data.build_time_hours,
      unit_type: "hours",
      is_per_build: true,
      position: 2
    )

    # Post-processing labor
    slicing_data.cost_line_items.create!(
      category: "labor",
      name: "Post-Processing Labor",
      description: "Part removal, cleaning, finishing",
      unit_cost: @params.labor_rate,
      quantity: @params.post_processing_time_per_part,
      unit_type: "hours",
      is_per_build: false,
      position: 3
    )
  end

  def create_consumable_items
    # Metal powder
    powder_cost_per_kg = @material.raw_material_price
    slicing_data.cost_line_items.create!(
      category: "consumables",
      name: "Metal Powder",
      description: "#{@material.name} powder",
      unit_cost: powder_cost_per_kg,
      quantity: slicing_data.total_powder_mass,
      unit_type: "kg",
      is_per_build: false,
      position: 1
    )

    # Inert gas
    gas_volume = slicing_data.build_time_hours * @params.gas_consumption_per_hour
    slicing_data.cost_line_items.create!(
      category: "consumables",
      name: "Inert Gas (Argon/N2)",
      description: "Build chamber atmosphere",
      unit_cost: @params.inert_gas_price,
      quantity: gas_volume,
      unit_type: "m³",
      is_per_build: true,
      position: 2
    )

    # Waste disposal
    unused_powder = slicing_data.total_powder_mass - slicing_data.part_mass
    non_recycled = unused_powder * (1 - @material.recycling_efficiency)

    slicing_data.cost_line_items.create!(
      category: "consumables",
      name: "Waste Disposal",
      description: "Non-recyclable powder disposal",
      unit_cost: @params.waste_disposal_cost_per_kg,
      quantity: non_recycled,
      unit_type: "kg",
      is_per_build: false,
      position: 3
    )
  end

  def create_energy_items
    # Electricity consumption
    energy_kwh = slicing_data.build_time_hours * @params.machine_power_consumption

    slicing_data.cost_line_items.create!(
      category: "energy",
      name: "Electrical Energy",
      description: "Machine power consumption",
      unit_cost: @params.electricity_rate,
      quantity: energy_kwh,
      unit_type: "kWh",
      is_per_build: true,
      position: 1
    )
  end

  def create_equipment_items
    # Machine depreciation
    annual_depreciation = @machine.purchase_price / @machine.lifespan_years
    hourly_rate = annual_depreciation / @params.annual_operating_hours

    slicing_data.cost_line_items.create!(
      category: "equipment",
      name: "Machine Depreciation",
      description: "#{@machine.name} amortization",
      unit_cost: hourly_rate,
      quantity: slicing_data.build_time_hours,
      unit_type: "hours",
      is_per_build: true,
      position: 1
    )
  end

end
