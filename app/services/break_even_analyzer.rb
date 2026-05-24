# app/services/break_even_analyzer.rb
#
# Enhanced Break-Even Analysis Module
# Calculates minimum, median, and maximum break-even scenarios
# for comprehensive financial risk assessment

class BreakEvenAnalyzer
  attr_reader :financial_analyzer, :slicing_data, :params, :calculator

  # Timeframe benchmarks (in months)
  LOW_RISK_THRESHOLD = 6      # Under 6 months is low risk
  MODERATE_RISK_THRESHOLD = 18 # 6-18 months is moderate risk
  # Over 18 months is high risk

  def initialize(financial_analyzer)
    @financial_analyzer = financial_analyzer
    @slicing_data = financial_analyzer.slicing_data
    @params = financial_analyzer.params
    @calculator = financial_analyzer.calculator
  end

  # ========== CORE BREAK-EVEN CALCULATIONS ==========

  def fixed_costs_annual
    # Annual amortized investment cost
    Rails.cache.fetch("fixed_costs_annual.slicing_data.#{slicing_data.id}") do
      financial_analyzer.effective_upfront_investment / params.analysis_horizon_years.to_f
    end
  end

  def variable_cost_per_part
    # This is the cost that varies with each part produced
    calculator.total_cost_per_part
  end

  def contribution_margin_per_part
    # Selling price - variable cost
    params.price_per_part - variable_cost_per_part
  end

  def contribution_margin_ratio
    return 0 if params.price_per_part.zero?
    
    (contribution_margin_per_part / params.price_per_part) * 100
  end

  # ========== STANDARD (MEDIAN) BREAK-EVEN ==========

  def break_even_units_median
    Rails.cache.fetch("break_even_units_median.slicing_data.#{slicing_data.id}") do
      return nil if contribution_margin_per_part <= 0
      
      (fixed_costs_annual / contribution_margin_per_part).ceil
    end
  end

  def break_even_revenue_median
    return nil unless break_even_units_median
    
    break_even_units_median * params.price_per_part
  end

  def break_even_builds_median
    return nil unless break_even_units_median
    
    (break_even_units_median.to_f / financial_analyzer.annual_parts_produced).ceil
  end

  def break_even_time_months_median
    return nil unless break_even_units_median
    
    annual_capacity = financial_analyzer.annual_parts_produced
    return nil if annual_capacity.zero?
    
    (break_even_units_median.to_f / annual_capacity * 12).round(1)
  end

  # ========== MINIMUM (LOW-RISK) SCENARIO ==========
  # Assumes optimistic conditions: lower fixed costs, higher utilization

  def fixed_costs_minimum
    # Assume 20% reduction in fixed costs (efficient operations)
    fixed_costs_annual * 0.80
  end

  def break_even_units_minimum
    Rails.cache.fetch("break_even_units_minimum.slicing_data.#{slicing_data.id}") do
      return nil if contribution_margin_per_part <= 0
      
      (fixed_costs_minimum / contribution_margin_per_part).ceil
    end
  end

  def break_even_revenue_minimum
    return nil unless break_even_units_minimum
    
    break_even_units_minimum * params.price_per_part
  end

  def break_even_builds_minimum
    return nil unless break_even_units_minimum
    
    (break_even_units_minimum.to_f / financial_analyzer.annual_parts_produced).ceil
  end

  def break_even_time_months_minimum
    return nil unless break_even_units_minimum
    
    # Scale planned annual output for optimistic utilization conditions.
    optimistic_utilization = [params.machine_utilization_rate * 1.2, 1.0].min
    utilization_adjustment = optimistic_utilization / [ params.machine_utilization_rate, 0.01 ].max
    annual_capacity = financial_analyzer.annual_parts_produced * utilization_adjustment
    
    return nil if annual_capacity.zero?
    
    (break_even_units_minimum.to_f / annual_capacity * 12).round(1)
  end

  # ========== MAXIMUM (HIGH-RISK) SCENARIO ==========
  # Assumes pessimistic conditions: higher fixed costs, lower utilization

  def fixed_costs_maximum
    # Assume 30% increase in fixed costs (inefficiencies, delays, additional costs)
    fixed_costs_annual * 1.30
  end

  def break_even_units_maximum
    Rails.cache.fetch("break_even_units_maximum.slicing_data.#{slicing_data.id}") do
      return nil if contribution_margin_per_part <= 0
      
      (fixed_costs_maximum / contribution_margin_per_part).ceil
    end
  end

  def break_even_revenue_maximum
    return nil unless break_even_units_maximum
    
    break_even_units_maximum * params.price_per_part
  end

  def break_even_builds_maximum
    return nil unless break_even_units_maximum
    
    (break_even_units_maximum.to_f / financial_analyzer.annual_parts_produced).ceil
  end

  def break_even_time_months_maximum
    return nil unless break_even_units_maximum
    
    # Scale planned annual output for pessimistic utilization conditions.
    pessimistic_utilization = params.machine_utilization_rate * 0.70
    utilization_adjustment = pessimistic_utilization / [ params.machine_utilization_rate, 0.01 ].max
    annual_capacity = financial_analyzer.annual_parts_produced * utilization_adjustment
    
    return nil if annual_capacity.zero?
    
    (break_even_units_maximum.to_f / annual_capacity * 12).round(1)
  end

  # ========== RISK ASSESSMENT ==========

  def risk_level_median
    time = break_even_time_months_median
    return "Unknown" unless time
    
    case time
    when 0..LOW_RISK_THRESHOLD
      "Low Risk"
    when LOW_RISK_THRESHOLD..MODERATE_RISK_THRESHOLD
      "Moderate Risk"
    else
      "High Risk"
    end
  end

  def risk_level_minimum
    time = break_even_time_months_minimum
    return "Unknown" unless time
    
    case time
    when 0..LOW_RISK_THRESHOLD
      "Low Risk"
    when LOW_RISK_THRESHOLD..MODERATE_RISK_THRESHOLD
      "Moderate Risk"
    else
      "High Risk"
    end
  end

  def risk_level_maximum
    time = break_even_time_months_maximum
    return "Unknown" unless time
    
    case time
    when 0..LOW_RISK_THRESHOLD
      "Low Risk"
    when LOW_RISK_THRESHOLD..MODERATE_RISK_THRESHOLD
      "Moderate Risk"
    else
      "High Risk"
    end
  end

  def overall_risk_assessment
    max_time = break_even_time_months_maximum
    
    return "Unable to assess" unless max_time
    
    if max_time > MODERATE_RISK_THRESHOLD
      "HIGH RISK: Maximum break-even period exceeds 18 months. Project requires substantial sales volume and extended time to become profitable."
    elsif max_time > LOW_RISK_THRESHOLD
      "MODERATE RISK: Break-even achievable within 18 months under normal conditions, but vulnerable to market fluctuations."
    else
      "LOW RISK: Break-even achievable within 6 months even under pessimistic conditions. Sustainable business model."
    end
  end

  # ========== CAPACITY ANALYSIS ==========

  def capacity_utilization_at_break_even
    return nil unless break_even_units_median
    
    max_annual_capacity = financial_analyzer.annual_parts_produced
    
    return nil if max_annual_capacity.zero?
    
    (break_even_units_median.to_f / max_annual_capacity * 100).round(1)
  end

  def profitability_buffer
    # How much sales can drop before hitting break-even
    current_annual_parts = financial_analyzer.annual_parts_produced
    
    return nil unless break_even_units_median && current_annual_parts > 0
    
    ((current_annual_parts - break_even_units_median) / current_annual_parts.to_f * 100).round(1)
  end

  def margin_of_safety_units
    # Units above break-even
    current_annual_parts = financial_analyzer.annual_parts_produced
    
    return nil unless break_even_units_median
    
    [current_annual_parts - break_even_units_median, 0].max
  end

  def margin_of_safety_revenue
    return nil unless margin_of_safety_units
    
    margin_of_safety_units * params.price_per_part
  end

  # ========== SHUTDOWN ANALYSIS ==========

  def should_shutdown?
    # If break-even is impossible or requires more than maximum capacity
    return true if contribution_margin_per_part <= 0
    return true if capacity_utilization_at_break_even && capacity_utilization_at_break_even > 100
    return true if break_even_time_months_maximum && break_even_time_months_maximum > 36 # 3 years
    
    false
  end

  def shutdown_recommendation
    if should_shutdown?
      "RECOMMEND SHUTDOWN: Break-even is not achievable within reasonable timeframe or production capacity."
    elsif risk_level_maximum == "High Risk"
      "CAUTION: Consider alternative cost structures or pricing strategies before proceeding."
    else
      "PROCEED: Break-even analysis supports business viability."
    end
  end

  # ========== SCENARIO COMPARISON ==========

  def scenario_comparison
    {
      minimum: {
        scenario: "Best Case (Optimistic)",
        fixed_costs: fixed_costs_minimum,
        break_even_units: break_even_units_minimum,
        break_even_revenue: break_even_revenue_minimum,
        break_even_builds: break_even_builds_minimum,
        break_even_months: break_even_time_months_minimum,
        risk_level: risk_level_minimum,
        assumptions: "80% of planned fixed costs, 120% utilization rate"
      },
      median: {
        scenario: "Standard (Expected)",
        fixed_costs: fixed_costs_annual,
        break_even_units: break_even_units_median,
        break_even_revenue: break_even_revenue_median,
        break_even_builds: break_even_builds_median,
        break_even_months: break_even_time_months_median,
        risk_level: risk_level_median,
        assumptions: "Planned fixed costs, standard utilization rate"
      },
      maximum: {
        scenario: "Worst Case (Pessimistic)",
        fixed_costs: fixed_costs_maximum,
        break_even_units: break_even_units_maximum,
        break_even_revenue: break_even_revenue_maximum,
        break_even_builds: break_even_builds_maximum,
        break_even_months: break_even_time_months_maximum,
        risk_level: risk_level_maximum,
        assumptions: "130% of planned fixed costs, 70% utilization rate"
      }
    }
  end

  # ========== COMPREHENSIVE SUMMARY ==========

  def break_even_summary
    {
      fundamentals: {
        fixed_costs_annual: fixed_costs_annual,
        variable_cost_per_part: variable_cost_per_part,
        selling_price_per_part: params.price_per_part,
        contribution_margin_per_part: contribution_margin_per_part,
        contribution_margin_ratio: contribution_margin_ratio
      },
      scenarios: scenario_comparison,
      risk_analysis: {
        overall_assessment: overall_risk_assessment,
        shutdown_recommendation: shutdown_recommendation,
        should_shutdown: should_shutdown?
      },
      capacity_metrics: {
        capacity_utilization_at_break_even: capacity_utilization_at_break_even,
        profitability_buffer_percentage: profitability_buffer,
        margin_of_safety_units: margin_of_safety_units,
        margin_of_safety_revenue: margin_of_safety_revenue
      },
      benchmarks: {
        low_risk_threshold_months: LOW_RISK_THRESHOLD,
        moderate_risk_threshold_months: MODERATE_RISK_THRESHOLD,
        current_annual_capacity_parts: financial_analyzer.annual_parts_produced
      }
    }
  end

  # ========== WHAT-IF ANALYSIS ==========

  def break_even_at_price(new_price)
    # Calculate break-even if price changes
    new_contribution = new_price - variable_cost_per_part
    return nil if new_contribution <= 0
    
    {
      price: new_price,
      contribution_margin: new_contribution,
      break_even_units: (fixed_costs_annual / new_contribution).ceil,
      break_even_revenue: ((fixed_costs_annual / new_contribution).ceil * new_price)
    }
  end

  def price_required_for_break_even_in_months(target_months)
    # What price is needed to break even within target timeframe?
    target_annual_parts = (financial_analyzer.annual_parts_produced * 
                          (target_months / 12.0))
    
    return nil if target_annual_parts.zero?
    
    # Required contribution margin per part
    required_contribution = fixed_costs_annual / target_annual_parts
    
    # Required price = variable cost + required contribution
    required_price = variable_cost_per_part + required_contribution
    
    {
      target_months: target_months,
      target_units: target_annual_parts.ceil,
      required_price: required_price.round(2),
      current_price: params.price_per_part,
      price_increase_needed: (required_price - params.price_per_part).round(2),
      price_increase_percentage: ((required_price / params.price_per_part - 1) * 100).round(1)
    }
  end
end
