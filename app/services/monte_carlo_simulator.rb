# app/services/monte_carlo_simulator.rb
require "numo/narray"
require "descriptive_statistics"
require "parallel"
require "finrb"

class MonteCarloSimulator
  attr_reader :slicing_data, :params, :iterations

  def initialize(slicing_data, iterations: 10_000)
    @slicing_data = slicing_data
    @params = slicing_data.effective_parameters
    @iterations = iterations
    @results = Rails.cache.fetch("monte_carlo.slicing_data.#{slicing_data.id}")
  end

  # Run the simulation with parallel processing and vectorized operations
  def run!
    return @results if @results.present?

    # Determine optimal thread count
    thread_count = Parallel.processor_count - 1

    # Run iterations in parallel
    results_array = Parallel.map(1..iterations, in_processes: thread_count) do
      # Each thread needs its own random seed
      # Thread.current[:random] = Random.new

      sampled_params = sample_parameters
      cost = calculate_cost_per_part(sampled_params)
      financial_metrics = calculate_financial_metrics(sampled_params, cost)

      {
        cost_per_part: cost,
        npv: financial_metrics[:npv],
        irr: financial_metrics[:irr],
        roi: financial_metrics[:roi],
        payback_period: financial_metrics[:payback_period]
      }
    end

    # Convert to Numo arrays for fast statistics
    @results = {
      cost_per_part: Numo::DFloat[*results_array.map { |r| r[:cost_per_part] }],
      npv: Numo::DFloat[*results_array.map { |r| r[:npv] }],
      irr: Numo::DFloat[*results_array.map { |r| r[:irr] }.compact],
      roi: Numo::DFloat[*results_array.map { |r| r[:roi] }],
      payback_period: Numo::DFloat[*results_array.map { |r| r[:payback_period] }.compact]
    }

    Rails.cache.write("monte_carlo.slicing_data.#{slicing_data.id}", @results)

    @results
  end

  # Ensure simulation has run
  attr_reader :results

  # ========== COST PER PART STATISTICS (Vectorized with Numo) ==========

  def cost_per_part_mean
    results[:cost_per_part].mean
  end

  def cost_per_part_std
    results[:cost_per_part].stddev
  end

  def cost_per_part_min
    results[:cost_per_part].min
  end

  def cost_per_part_max
    results[:cost_per_part].max
  end

  def cost_per_part_percentile(p)
    sorted = results[:cost_per_part].sort
    index = (p / 100.0 * sorted.size).ceil - 1
    sorted[[ index, 0 ].max]
  end

  def cost_per_part_histogram(bins: 50)
    data = results[:cost_per_part]
    min_val = data.min
    max_val = data.max
    range = max_val - min_val

    return { bin_centers: [ min_val ], frequencies: [ data.size ] } if range == 0

    bin_width = range / bins.to_f

    # Vectorized histogram calculation
    bin_indices = ((data - min_val) / bin_width).floor
    bin_indices[bin_indices >= bins] = bins - 1

    # Count frequencies
    histogram = Array.new(bins, 0)
    bin_indices.each { |idx| histogram[idx] += 1 }

    bin_centers = bins.times.map { |i| min_val + (i + 0.5) * bin_width }
    { bin_centers: bin_centers, frequencies: histogram }
  end

  # ========== NPV STATISTICS (Vectorized with Numo) ==========

  def npv_mean
    results[:npv].mean
  end

  def npv_std
    results[:npv].stddev
  end

  def npv_min
    results[:npv].min
  end

  def npv_max
    results[:npv].max
  end

  def npv_percentile(p)
    sorted = results[:npv].sort
    index = (p / 100.0 * sorted.size).ceil - 1
    sorted[[ index, 0 ].max]
  end

  def npv_positive_probability
    positive_count = (results[:npv] > 0).count_true
    (positive_count / results[:npv].size.to_f) * 100
  end

  def npv_histogram(bins: 50)
    data = results[:npv]
    min_val = data.min
    max_val = data.max
    range = max_val - min_val

    return { bin_centers: [ min_val ], frequencies: [ data.size ] } if range == 0

    bin_width = range / bins.to_f

    # Vectorized histogram calculation
    bin_indices = ((data - min_val) / bin_width).floor
    bin_indices[bin_indices >= bins] = bins - 1

    # Count frequencies
    histogram = Array.new(bins, 0)
    bin_indices.each { |idx| histogram[idx] += 1 }

    bin_centers = bins.times.map { |i| min_val + (i + 0.5) * bin_width }
    { bin_centers: bin_centers, frequencies: histogram }
  end

  # ========== IRR STATISTICS (Vectorized with Numo) ==========

  def irr_mean
    return nil if results[:irr].empty?

    results[:irr].mean
  end

  def irr_std
    return nil if results[:irr].empty?

    results[:irr].stddev
  end

  def irr_min
    return nil if results[:irr].empty?

    results[:irr].min
  end

  def irr_max
    return nil if results[:irr].empty?

    results[:irr].max
  end

  def irr_percentile(p)
    return nil if results[:irr].empty?

    sorted = results[:irr].sort
    index = (p / 100.0 * sorted.size).ceil - 1
    sorted[[ index, 0 ].max]
  end

  def irr_histogram(bins: 50)
    return nil if results[:irr].empty?

    data = results[:irr]
    min_val = data.min
    max_val = data.max
    range = max_val - min_val

    return { bin_centers: [ min_val ], frequencies: [ data.size ] } if range == 0

    bin_width = range / bins.to_f

    # Vectorized histogram calculation
    bin_indices = ((data - min_val) / bin_width).floor
    bin_indices[bin_indices >= bins] = bins - 1

    # Count frequencies
    histogram = Array.new(bins, 0)
    bin_indices.each { |idx| histogram[idx] += 1 }

    bin_centers = bins.times.map { |i| min_val + (i + 0.5) * bin_width }
    { bin_centers: bin_centers, frequencies: histogram }
  end

  # ========== ROI STATISTICS (Vectorized with Numo) ==========

  def roi_mean
    results[:roi].mean
  end

  def roi_std
    results[:roi].stddev
  end

  def roi_min
    results[:roi].min
  end

  def roi_max
    results[:roi].max
  end

  def roi_percentile(p)
    sorted = results[:roi].sort
    index = (p / 100.0 * sorted.size).ceil - 1
    sorted[[ index, 0 ].max]
  end

  def roi_histogram(bins: 50)
    data = results[:roi]
    min_val = data.min
    max_val = data.max
    range = max_val - min_val

    return { bin_centers: [ min_val ], frequencies: [ data.size ] } if range == 0

    bin_width = range / bins.to_f

    # Vectorized histogram calculation
    bin_indices = ((data - min_val) / bin_width).floor
    bin_indices[bin_indices >= bins] = bins - 1

    # Count frequencies
    histogram = Array.new(bins, 0)
    bin_indices.each { |idx| histogram[idx] += 1 }

    bin_centers = bins.times.map { |i| min_val + (i + 0.5) * bin_width }
    { bin_centers: bin_centers, frequencies: histogram }
  end

  # ========== PAYBACK PERIOD STATISTICS ==========

  def payback_period_mean
    return nil if results[:payback_period].empty?

    results[:payback_period].mean
  end

  def payback_period_std
    return nil if results[:payback_period].empty?

    results[:payback_period].stddev
  end

  def payback_period_min
    return nil if results[:payback_period].empty?

    results[:payback_period].min
  end

  def payback_period_max
    return nil if results[:payback_period].empty?

    results[:payback_period].max
  end

  def payback_period_percentile(p)
    return nil if results[:payback_period].empty?

    sorted = results[:payback_period].sort
    index = (p / 100.0 * sorted.size).ceil - 1
    sorted[[ index, 0 ].max]
  end

  def payback_period_histogram(bins: 50)
    return nil if results[:payback_period].empty?

    data = results[:payback_period]
    min_val = data.min
    max_val = data.max
    range = max_val - min_val

    return { bin_centers: [ min_val ], frequencies: [ data.size ] } if range == 0

    bin_width = range / bins.to_f

    # Vectorized histogram calculation
    bin_indices = ((data - min_val) / bin_width).floor
    bin_indices[bin_indices >= bins] = bins - 1

    # Count frequencies
    histogram = Array.new(bins, 0)
    bin_indices.each { |idx| histogram[idx] += 1 }

    bin_centers = bins.times.map { |i| min_val + (i + 0.5) * bin_width }
    { bin_centers: bin_centers, frequencies: histogram }
  end

  # ========== SUMMARY STATISTICS ==========

  def summary_statistics
    {
      cost_per_part: {
        mean: cost_per_part_mean,
        std: cost_per_part_std,
        min: cost_per_part_min,
        max: cost_per_part_max,
        p5: cost_per_part_percentile(5),
        p50: cost_per_part_percentile(50),
        p95: cost_per_part_percentile(95)
      },
      npv: {
        mean: npv_mean,
        std: npv_std,
        min: npv_min,
        max: npv_max,
        p5: npv_percentile(5),
        p50: npv_percentile(50),
        p95: npv_percentile(95),
        positive_probability: npv_positive_probability
      },
      irr: {
        mean: irr_mean,
        std: irr_std,
        min: irr_min,
        max: irr_max,
        p5: irr_percentile(5),
        p50: irr_percentile(50),
        p95: irr_percentile(95)
      },
      roi: {
        mean: roi_mean,
        std: roi_std,
        min: roi_min,
        max: roi_max,
        p5: roi_percentile(5),
        p50: roi_percentile(50),
        p95: roi_percentile(95)
      },
      payback_period: {
        mean: payback_period_mean,
        std: payback_period_std,
        min: payback_period_min,
        max: payback_period_max,
        p5: payback_period_percentile(5),
        p50: payback_period_percentile(50),
        p95: payback_period_percentile(95)
      }
    }
  end

  private

  def effective_upfront_investment
    slicing_data.effective_upfront_investment
  end

  # ========== PARAMETER SAMPLING ==========

  def sample_parameters
    {
      # Material costs - normal distribution with volatility
      powder_price: sample_normal(
        slicing_data.material.raw_material_price,
        slicing_data.material.raw_material_price * (params.cost_volatility || 0.1)
      ),

      # Energy costs - normal distribution
      electricity_rate: sample_normal(
        params.electricity_rate,
        params.electricity_rate * (params.cost_volatility || 0.1)
      ),

      # Labor costs - normal distribution
      labor_rate: sample_normal(
        params.labor_rate,
        params.labor_rate * (params.cost_volatility || 0.05)
      ),

      # Build time - normal distribution (± 15%)
      build_time_multiplier: sample_normal(1.0, 0.15),

      # Material utilization - uniform between 0.5 and material's recycling efficiency
      material_utilization: sample_uniform(0.5, [ slicing_data.material.recycling_efficiency, 0.95 ].min),

      # Recycling efficiency - uniform around material's base value
      recycling_efficiency: sample_uniform(
        [ slicing_data.material.recycling_efficiency - 0.05, 0.5 ].max,
        [ slicing_data.material.recycling_efficiency + 0.05, 0.95 ].min
      ),

      # Revenue - normal distribution with volatility
      price_per_part: sample_normal(
        params.price_per_part,
        params.price_per_part * (params.revenue_volatility || 0.1)
      ),

      # Discount rate - normal distribution (± 2%)
      discount_rate: sample_normal(
        params.discount_rate,
        0.02
      ).clamp(0.01, 0.30),

      # Machine utilization - normal distribution
      machine_utilization: sample_normal(
        params.machine_utilization_rate,
        0.05
      ).clamp(0.5, 0.95)
    }
  end

  # Normal distribution sampling (Box-Muller transform)
  def sample_normal(mean, std_dev)
    return mean if std_dev <= 0

    # Thread-safe random number generator
    rng = Thread.current[:random] || Random.new

    u1 = rng.rand
    u2 = rng.rand

    z0 = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math::PI * u2)
    mean + z0 * std_dev
  end

  # Uniform distribution sampling
  def sample_uniform(min, max)
    rng = Thread.current[:random] || Random.new
    min + rng.rand * (max - min)
  end

  # ========== COST CALCULATION WITH SAMPLED PARAMETERS ==========

  def calculate_cost_per_part(sampled)
    # Part mass calculation
    part_volume_cm3 = slicing_data.part_volume / 1000.0
    support_volume_cm3 = (slicing_data.support_volume || 0) / 1000.0
    total_volume_cm3 = part_volume_cm3 + support_volume_cm3
    part_mass = (total_volume_cm3 * slicing_data.material.density) / 1000.0

    # Total powder mass with sampled utilization
    total_powder_mass = part_mass / sampled[:material_utilization]

    # Build time with sampled variation
    build_time = slicing_data.build_time_hours.to_f * sampled[:build_time_multiplier]

    # Material costs
    powder_cost = total_powder_mass * sampled[:powder_price]

    # Recycled powder
    unused_powder = total_powder_mass - part_mass
    recycled_powder = unused_powder * sampled[:recycling_efficiency]
    non_recycled_powder = total_powder_mass - part_mass - recycled_powder

    waste_cost = non_recycled_powder * params.waste_disposal_cost_per_kg
    gas_cost = build_time * params.gas_consumption_per_hour * params.inert_gas_price
    consumables_cost = powder_cost + gas_cost + waste_cost

    # Energy cost
    energy_consumption = build_time * params.machine_power_consumption
    energy_cost = energy_consumption * sampled[:electricity_rate]

    # Equipment cost
    machine_hourly_rate = (slicing_data.machine.purchase_price / slicing_data.machine.lifespan_years +
                          slicing_data.machine.annual_maintenance_cost) / params.annual_operating_hours
    equipment_cost = machine_hourly_rate * build_time

    # Labor cost
    operator_time = build_time + (params.post_processing_time_per_part * slicing_data.annual_parts_produced)
    labor_cost = operator_time * sampled[:labor_rate]
    setup_cost = params.setup_time_hours * sampled[:labor_rate]
    total_labor = labor_cost + setup_cost

    # Facility cost
    facility_cost_per_hour = (params.annual_rent + params.annual_utilities + params.annual_admin) / params.annual_operating_hours
    facility_cost = facility_cost_per_hour * build_time

    # Digital cost
    digital_cost_per_hour = (params.annual_software_cost + params.annual_hpc_cost) / params.annual_operating_hours
    digital_cost = digital_cost_per_hour * build_time

    # Maintenance cost
    maintenance_cost = (params.total_annual_maintenance / params.annual_operating_hours) * build_time

    # Total cost per build
    total_cost_per_build = consumables_cost + energy_cost + equipment_cost +
                           total_labor + facility_cost + digital_cost + maintenance_cost

    # Cost per part
    total_cost_per_build / slicing_data.annual_parts_produced
  end

  # ========== FINANCIAL METRICS CALCULATION (Using FinRB) ==========

  def calculate_financial_metrics(sampled, cost_per_part)
    annual_parts = slicing_data.annual_parts_produced
    annual_revenue = annual_parts * sampled[:price_per_part]
    annual_cost = annual_parts * cost_per_part
    annual_profit = annual_revenue - annual_cost

    # Build cash flow array: [initial_investment (negative), then annual profits]
    cash_flows = [ -effective_upfront_investment ]
    params.analysis_horizon_years.times do
      cash_flows << annual_profit
    end

    # NPV calculation using FinRB
    npv = begin
      Finrb::Utils.npv(r: sampled[:discount_rate], cf: cash_flows)
    rescue StandardError => e
      puts e.message
      # Fallback to manual calculation if FinRB fails
      calculate_npv_manual(cash_flows, sampled[:discount_rate])
    end
    # IRR is undefined unless cash flows contain at least one positive and one negative value.
    # Return nil for non-computable scenarios so the simulation continues.
    irr = if cash_flows.any?(&:positive?) && cash_flows.any?(&:negative?)
      begin
        irr_decimal = Finance::Calculations.irr(cash_flows)
        irr_decimal ? irr_decimal * 100 : nil # Convert to percentage
      rescue StandardError
        nil
      end
    else
      nil
    end

    # Payback Period calculation using FinRB
    payback_period = begin
      Finrb::Utils.payback(cash_flows)
    rescue StandardError => e
      calculate_payback_manual(cash_flows)
    end

    # ROI calculation
    total_profit = annual_profit * params.analysis_horizon_years
    roi = effective_upfront_investment > 0 ? (total_profit / effective_upfront_investment) * 100 : 0

    {
      npv: npv,
      irr: irr,
      roi: roi,
      payback_period: payback_period
    }
  end

  # Fallback NPV calculation if FinRB fails
  def calculate_npv_manual(cash_flows, discount_rate)
    npv = 0
    cash_flows.each_with_index do |cf, period|
      npv += cf / ((1 + discount_rate)**period)
    end
    npv
  end

  # Fallback payback period calculation if FinRB fails
  def calculate_payback_manual(cash_flows)
    cumulative = 0
    cash_flows.each_with_index do |cf, period|
      cumulative += cf
      return period.to_f if cumulative >= 0 && period > 0
    end
    nil # Investment never pays back
  end
end
