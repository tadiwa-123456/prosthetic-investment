# app/services/cost_calculator.rb
class CostCalculator
  attr_reader :slicing_data, :machine, :material, :params

  def initialize(slicing_data)
    @slicing_data = slicing_data
    @machine = slicing_data.machine
    @material = slicing_data.material
    @params = slicing_data.effective_parameters
  end

  # ========== MATERIAL COSTS ==========

  def powder_cost
    # C_powder = M_total_powder × P_powder
    slicing_data.total_powder_mass * material.raw_material_price
  end

  def powder_cost_per_build
    powder_cost * slicing_data.parts_per_build
  end

  def recycled_powder_mass
    # M_recycled = (M_total - M_part) × recycling_efficiency
    unused_powder = slicing_data.total_powder_mass - slicing_data.part_mass
    unused_powder * material.recycling_efficiency
  end

  def non_recycled_powder_mass
    slicing_data.total_powder_mass - slicing_data.part_mass - recycled_powder_mass
  end

  def waste_cost
    # C_waste = M_non_recycled × C_disposal
    non_recycled_powder_mass * params.waste_disposal_cost_per_kg
  end

  def waste_cost_per_build
    waste_cost * slicing_data.parts_per_build
  end

  def gas_cost
    # C_gas = V_gas × P_gas
    # Gas consumption based on build time
    gas_volume = slicing_data.build_time_hours * params.gas_consumption_per_hour
    (gas_volume * params.inert_gas_price) / slicing_data.parts_per_build
  end

  def gas_cost_per_build
    gas_cost * slicing_data.parts_per_build
  end

  def consumables_cost
    # C_consumables = (Powder cost) + (Gas cost) + (Waste cost)
    powder_cost + gas_cost + waste_cost
  end

  def consumables_cost_per_build
    # C_consumables = (Powder cost) + (Gas cost) + (Waste cost)
    consumables_cost * slicing_data.parts_per_build
  end

  def consumables_cost_per_kg
    consumables_cost / slicing_data.part_mass
  end

  # ========== ENERGY COSTS ==========

  def energy_consumption
    # E_part = Build time × Machine power consumption
    (slicing_data.build_time_hours / slicing_data.parts_per_build) * params.machine_power_consumption
  end

  def energy_cost
    # C_energy = E_part × Electricity rate
    energy_consumption * params.electricity_rate
  end

  def energy_cost_per_build
    energy_cost * slicing_data.parts_per_build
  end

  def energy_efficiency_per_kg
    energy_consumption / slicing_data.part_mass
  end

  # ========== EQUIPMENT COSTS ==========

  def machine_hourly_rate
    # Machine hourly rate = (Purchase + Maintenance) / Annual Hours
    annual_cost = (machine.purchase_price / machine.lifespan_years) +
                  machine.annual_maintenance_cost
    annual_cost / params.annual_operating_hours
  end

  def equipment_cost_per_build
    # C_equipment = Machine hourly rate × Build time
    machine_hourly_rate * slicing_data.build_time_hours
  end

  def equipment_cost_per_part
    equipment_cost_per_build / slicing_data.parts_per_build
  end

  # ========== LABOR COSTS ==========

  def setup_cost
    # C_setup = Setup time × Labor rate
    params.setup_time_hours * params.labor_rate
  end

  def operator_time
    # Operator supervises build + post-processing
    slicing_data.build_time_hours +
      (params.post_processing_time_per_part * slicing_data.parts_per_build)
  end

  def labor_cost_per_build
    # C_labor = Operator time × Labor rate
    operator_time * params.labor_rate
  end

  def labor_cost_per_part
    (labor_cost_per_build + setup_cost) / slicing_data.parts_per_build
  end

  # ========== FACILITY COSTS ==========

  def facility_cost_per_hour
    (params.annual_rent + params.annual_utilities + params.annual_admin) / params.annual_operating_hours
  end

  def facility_cost_per_build
    # C_facility = (Rent + Utilities + Admin) / Annual hours × Build time
    facility_cost_per_hour * slicing_data.build_time_hours
  end

  def facility_cost_per_part
    facility_cost_per_build / slicing_data.parts_per_build
  end

  # ========== DIGITAL INFRASTRUCTURE ==========

  def digital_cost_per_hour
    (params.annual_software_cost + params.annual_hpc_cost) / params.annual_operating_hours
  end

  def digital_cost_per_build
    # C_digital = (Software + HPC) / Annual hours × Build time
    digital_cost_per_hour * slicing_data.build_time_hours
  end

  def digital_cost_per_part
    digital_cost_per_build / slicing_data.parts_per_build
  end

  # ========== MAINTENANCE COSTS ==========

  def total_annual_maintenance
    # Using machine's maintenance cost as it's machine-specific
    machine.annual_maintenance_cost
  end

  def maintenance_cost_per_build
    # Amortize annual maintenance over builds
    total_annual_maintenance / params.annual_operating_hours *
      slicing_data.build_time_hours
  end

  def maintenance_cost_per_part
    maintenance_cost_per_build / slicing_data.parts_per_build
  end

  # ========== TOTAL COSTS ==========

  def total_cost_per_build
    consumables_cost_per_build +
      energy_cost_per_build +
      equipment_cost_per_build +
      labor_cost_per_build +
      facility_cost_per_build +
      digital_cost_per_build +
      maintenance_cost_per_build
  end

  def total_cost_per_part
    total_cost_per_build / slicing_data.parts_per_build
  end

  # ========== SUSTAINABILITY METRICS ==========

  def carbon_footprint_energy
    # CF_energy = E_part × Grid emission factor
    energy_consumption * params.grid_emission_factor
  end

  def carbon_footprint_material
    # CF_material = M_part × Embodied carbon
    slicing_data.part_mass * material.embodied_carbon
  end

  def carbon_footprint_digital
    # CF_digital = E_digital × Grid emission factor
    digital_energy = slicing_data.build_time_hours * 0.5 # Assume 0.5 kW for digital
    digital_energy * params.grid_emission_factor
  end

  def total_carbon_footprint
    carbon_footprint_energy + carbon_footprint_material + carbon_footprint_digital
  end

  def carbon_footprint_per_kg
    total_carbon_footprint / slicing_data.part_mass
  end

  # ========== MATERIAL EFFICIENCY METRICS ==========

  def waste_ratio
    # Waste ratio = (Total powder - Part - Recycled) / Total powder
    (slicing_data.total_powder_mass - slicing_data.part_mass - recycled_powder_mass) /
      slicing_data.total_powder_mass
  end

  def recycling_efficiency
    recycled_powder_mass / slicing_data.total_powder_mass
  end

  # ========== BREAKDOWN FOR VISUALIZATION ==========

  def cost_breakdown
    {
      consumables: consumables_cost_per_build,
      energy: energy_cost_per_build,
      equipment: equipment_cost_per_build,
      labor: labor_cost_per_build + setup_cost,
      facility: facility_cost_per_build,
      digital: digital_cost_per_build,
      maintenance: maintenance_cost_per_build
    }
  end

  def cost_breakdown_percentages
    total = total_cost_per_build
    cost_breakdown.transform_values { |v| (v / total * 100).round(1) }
  end
end
