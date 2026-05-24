# app/services/line_items_calculator.rb
class LineItemsCalculator
  attr_reader :slicing_data

  def initialize(slicing_data)
    @slicing_data = slicing_data
    @params = slicing_data.effective_parameters
  end

  # Update all line item quantities based on actual part data
  def calculate_quantities!
    return unless slicing_data.machine && slicing_data.material

    calculate_labor_quantities!
    calculate_consumable_quantities!
    calculate_energy_quantities!
    calculate_equipment_quantities!
    calculate_facility_quantities!
    calculate_digital_quantities!
    # Maintenance quantities are already set (1 per build)
  end

  private

  def calculate_labor_quantities!
    # Build Supervision - use actual build time
    supervision = slicing_data.cost_line_items.find_by(category: "labor", name: "Build Supervision")
    return unless supervision && slicing_data.build_time_hours

    supervision.update(quantity: slicing_data.build_time_hours)

    # Setup Labor - already has default
    # Post-Processing Labor - already has default per part
  end

  def calculate_consumable_quantities!
    material = slicing_data.material

    # Metal Powder - update quantity ONLY (preserve user-provided unit_cost)
    powder = slicing_data.cost_line_items.find_by(category: "consumables", name: "Metal Powder")
    if powder && slicing_data.total_powder_mass
      powder.update(quantity: slicing_data.total_powder_mass)
    end

    # Inert Gas - based on build time
    gas = slicing_data.cost_line_items.find_by(category: "consumables", name: "Inert Gas (Argon/N2)")
    if gas && slicing_data.build_time_hours
      gas_volume = slicing_data.build_time_hours * @params.gas_consumption_per_hour
      gas.update(quantity: gas_volume)
    end

    # Waste Disposal - non-recyclable powder
    waste = slicing_data.cost_line_items.find_by(category: "consumables", name: "Waste Disposal")
    return unless waste && slicing_data.total_powder_mass && slicing_data.part_mass

    unused_powder = slicing_data.total_powder_mass - slicing_data.part_mass
    non_recycled = unused_powder * material.recycling_efficiency
    waste.update(quantity: non_recycled.clamp(0, Float::INFINITY))
  end

  def calculate_energy_quantities!
    # Electrical Energy - based on build time and machine power
    energy = slicing_data.cost_line_items.find_by(category: "energy", name: "Electrical Energy")
    return unless energy && slicing_data.build_time_hours

    energy_kwh = slicing_data.build_time_hours * @params.machine_power_consumption
    energy.update(quantity: energy_kwh)
  end

  def calculate_equipment_quantities!
    # Machine Depreciation - update quantity ONLY (preserve user-provided unit_cost if set)
    depreciation = slicing_data.cost_line_items.find_by(category: "equipment", name: "Machine Depreciation")
    return unless depreciation && slicing_data.build_time_hours && slicing_data.machine

    # Only update quantity from build time, don't override unit_cost
    depreciation.update(quantity: slicing_data.build_time_hours)
  end

  def calculate_facility_quantities!
    # All facility items use build time as quantity
    return unless slicing_data.build_time_hours

    slicing_data.cost_line_items.facility_items.each do |item|
      item.update(quantity: slicing_data.build_time_hours)
    end
  end

  def calculate_digital_quantities!
    # All digital items use build time as quantity
    return unless slicing_data.build_time_hours

    slicing_data.cost_line_items.digital_items.each do |item|
      item.update(quantity: slicing_data.build_time_hours)
    end
  end
end
