# app/services/financial_analyzer.rb
require "finrb"

class FinancialAnalyzer
  attr_reader :slicing_data, :calculator, :params

  def initialize(slicing_data, calculator)
    @slicing_data = slicing_data
    @calculator = calculator
    @params = slicing_data.effective_parameters
  end

  # ========== BREAK-EVEN ANALYSIS (NEW) ==========

  def break_even_analyzer
    @break_even_analyzer ||= BreakEvenAnalyzer.new(self)
  end

  # Delegate main break-even methods for convenience
  def break_even_analysis
    break_even_analyzer.break_even_summary
  end

  def break_even_units
    break_even_analyzer.break_even_units_median
  end

  def break_even_revenue
    break_even_analyzer.break_even_revenue_median
  end

  def break_even_time_months
    break_even_analyzer.break_even_time_months_median
  end

  def break_even_scenarios
    break_even_analyzer.scenario_comparison
  end

  def effective_upfront_investment
    slicing_data.effective_upfront_investment
  end

  # ========== REVENUE CALCULATIONS ==========

  def revenue_per_build
    Rails.cache.fetch("revenue_per_build.slicing_data.#{slicing_data.id}") do
      annual_parts_produced * params.price_per_part
    end
  end

  def revenue_per_part
    params.price_per_part
  end

  def profit_per_build
    Rails.cache.fetch("profit_per_build.slicing_data.#{slicing_data.id}") do
      revenue_per_build - calculator.total_cost_per_build
    end
  end

  def profit_per_part
    Rails.cache.fetch("profit_per_part.slicing_data.#{slicing_data.id}") do
      revenue_per_part - calculator.total_cost_per_part
    end
  end

  def profit_margin_percentage
    return 0 if revenue_per_build.zero?

    Rails.cache.fetch("profit_margin.slicing_data.#{slicing_data.id}") do
      (profit_per_build / revenue_per_build) * 100
    end
  end

  # ========== ANNUAL PROJECTIONS ==========

  def builds_per_year
    1
  end

  def annual_parts_produced
    Rails.cache.fetch("annual_parts_produced.slicing_data.#{slicing_data.id}") do
      slicing_data.annual_parts_produced
    end
  end

  def annual_revenue
    Rails.cache.fetch("annual_revenue.slicing_data.#{slicing_data.id}") do
      annual_parts_produced * revenue_per_part
    end
  end

  def annual_costs
    Rails.cache.fetch("annual_costs.slicing_data.#{slicing_data.id}") do
      annual_parts_produced * calculator.total_cost_per_part
    end
  end

  def annual_profit
    Rails.cache.fetch("annual_profit.slicing_data.#{slicing_data.id}") do
      annual_revenue - annual_costs
    end
  end

  # ========== MULTI-YEAR CASH FLOWS ==========

  def cash_flows
    Rails.cache.fetch("cash_flows.slicing_data.#{slicing_data.id}") do
      build_cash_flows
    end
  end

  def cash_flow_array
    # Returns array format for FinRB: [initial_investment, year1, year2, ...]

    Rails.cache.fetch("cash_flow_array.slicing_data.#{slicing_data.id}") do
      [ -effective_upfront_investment ] + Array.new(params.analysis_horizon_years, annual_profit)
    end
  end

  # ========== NPV CALCULATION (Using FinRB) ==========

  def net_present_value
    Rails.cache.fetch("npv.slicing_data.#{slicing_data.id}") do
      Finrb::Utils.npv(params.discount_rate, cash_flow_array)
    rescue StandardError
      # Fallback to manual calculation
      calculate_npv_manual
    end
  end

  def npv_positive?
    net_present_value.positive?
  end

  # ========== IRR CALCULATION (Using FinRB) ==========

  def internal_rate_of_return
    Rails.cache.fetch("irr.slicing_data.#{slicing_data.id}") do
      irr_decimal = Finance::Calculations.irr(cash_flow_array)
      irr_decimal ? irr_decimal * 100 : nil # Convert to percentage
    rescue StandardError
      # IRR cannot be computed when all cash flows share the same sign
      # (e.g. zero upfront investment) — return nil so the view renders gracefully.
      nil
    end
  end

  # ========== ROI CALCULATION ==========

  def return_on_investment
    Rails.cache.fetch("roi.slicing_data.#{slicing_data.id}") do
      total_profit = annual_profit * params.analysis_horizon_years
      return 0 if effective_upfront_investment.zero?

      (total_profit / effective_upfront_investment) * 100
    end
  end

  # ========== PAYBACK PERIOD (Using FinRB) ==========

  def payback_period_years
    Rails.cache.fetch("payback_period.slicing_data.#{slicing_data.id}") do
      Finrb::Utils.payback(cash_flow_array)
    rescue StandardError
      # Fallback to manual calculation
      return nil if annual_profit <= 0

      effective_upfront_investment / annual_profit.to_f
    end
  end

  def payback_within_horizon?
    period = payback_period_years
    return false if period.nil?

    period <= params.analysis_horizon_years
  end

  # ========== BREAK-EVEN ANALYSIS ==========

  def break_even_parts_per_year
    return nil if profit_per_part <= 0

    # Annual fixed costs (amortized investment)
    fixed_costs = effective_upfront_investment / params.analysis_horizon_years
    (fixed_costs / profit_per_part).ceil
  end

  def break_even_price_per_part
    calculator.total_cost_per_part
  end

  # ========== INVESTMENT VIABILITY ==========

  def investment_viable?
    npv_positive? &&
      return_on_investment > (params.minimum_acceptable_return || 0) &&
      payback_within_horizon?
  end

  def viability_score
    Rails.cache.fetch("viability_score.slicing_data.#{slicing_data.id}") do
      calculate_viability_score
    end
  end

  def viability_rating
    score = viability_score
    case score
    when 80..100 then "Excellent"
    when 60..79 then "Good"
    when 40..59 then "Moderate"
    when 20..39 then "Poor"
    else "Not Viable"
    end
  end

  # ========== SENSITIVITY METRICS ==========

  def price_sensitivity
    Rails.cache.fetch("price_sensitivity.slicing_data.#{slicing_data.id}") do
      base_profit = profit_per_part
      return 0 if base_profit.zero?

      new_price = params.price_per_part * 1.1
      new_profit = new_price - calculator.total_cost_per_part

      ((new_profit - base_profit) / base_profit) * 100
    end
  end

  def cost_sensitivity
    Rails.cache.fetch("cost_sensitivity.slicing_data.#{slicing_data.id}") do
      base_profit = profit_per_part
      return 0 if base_profit.zero?

      new_cost = calculator.total_cost_per_part * 1.1
      new_profit = params.price_per_part - new_cost

      ((new_profit - base_profit) / base_profit) * 100
    end
  end

  # ========== PROFITABILITY INDEX ==========

  def profitability_index
    Rails.cache.fetch("profitability_index.slicing_data.#{slicing_data.id}") do
      return 0 if effective_upfront_investment.zero?

      # PI = PV of future cash flows / Initial Investment
      present_value_of_cash_flows = net_present_value + effective_upfront_investment
      present_value_of_cash_flows / effective_upfront_investment
    end
  end

  # ========== DISCOUNTED PAYBACK PERIOD ==========

  def discounted_payback_period
    Rails.cache.fetch("discounted_payback_period.slicing_data.#{slicing_data.id}") do
      calculate_discounted_payback
    end
  end

  # ========== MODIFIED INTERNAL RATE OF RETURN (MIRR) ==========

  def modified_internal_rate_of_return
    Rails.cache.fetch("mirr.slicing_data.#{slicing_data.id}") do
      # MIRR accounts for reinvestment rate
      finance_rate = params.discount_rate
      reinvest_rate = params.discount_rate

      Finrb::Utils.mirr(cash_flow_array, finance_rate, reinvest_rate) * 100
    rescue StandardError
      nil
    end
  end

  # ========== SUMMARY STATISTICS ==========

  def financial_summary
    {
      revenue: {
        per_part: revenue_per_part,
        per_build: revenue_per_build,
        annual: annual_revenue
      },
      costs: {
        per_part: calculator.total_cost_per_part,
        per_build: calculator.total_cost_per_build,
        annual: annual_costs
      },
      profitability: {
        profit_per_part: profit_per_part,
        profit_per_build: profit_per_build,
        annual_profit: annual_profit,
        profit_margin: profit_margin_percentage
      },
      investment_metrics: {
        npv: net_present_value,
        irr: internal_rate_of_return,
        roi: return_on_investment,
        payback_period: payback_period_years,
        profitability_index: profitability_index,
        mirr: modified_internal_rate_of_return
      },
      viability: {
        score: viability_score,
        rating: viability_rating,
        is_viable: investment_viable?
      },
      sensitivity: {
        price_sensitivity: price_sensitivity,
        cost_sensitivity: cost_sensitivity
      },
      operations: {
        annual_parts_produced: annual_parts_produced
      }
    }
  end

  private

  def build_cash_flows
    horizon = params.analysis_horizon_years
    flows = []

    # Year 0: Initial investment (negative cash flow)
    flows << {
      year: 0,
      revenue: 0,
      costs: effective_upfront_investment,
      net_cash_flow: -effective_upfront_investment,
      cumulative_cash_flow: -effective_upfront_investment
    }

    cumulative = -effective_upfront_investment

    # Years 1 to N: Operating cash flows
    (1..horizon).each do |year|
      revenue = annual_revenue
      costs = annual_costs
      net = revenue - costs
      cumulative += net

      flows << {
        year: year,
        revenue: revenue,
        costs: costs,
        net_cash_flow: net,
        cumulative_cash_flow: cumulative
      }
    end

    flows
  end

  def calculate_viability_score
    score = 0

    # NPV contribution (30 points)
    if npv_positive?
      score += 30
      # Bonus for high NPV (guard against zero upfront investment)
      unless effective_upfront_investment.zero?
        npv_ratio = net_present_value / effective_upfront_investment
        score += [ npv_ratio * 10, 20 ].min
      end
    end

    # ROI contribution (25 points)
    roi = return_on_investment
    score += [ roi / 4, 25 ].min if roi > 0

    # Payback period contribution (25 points)
    if payback_within_horizon?
      period = payback_period_years
      # Faster payback = higher score
      score += 25 * (1 - (period / params.analysis_horizon_years))
    end

    score.round
  end

  def calculate_npv_manual
    discount_rate = params.discount_rate
    npv = -effective_upfront_investment

    (1..params.analysis_horizon_years).each do |year|
      present_value = annual_profit / ((1 + discount_rate)**year)
      npv += present_value
    end

    npv
  end

  def calculate_discounted_payback
    discount_rate = params.discount_rate
    cumulative = -effective_upfront_investment

    (1..params.analysis_horizon_years).each do |year|
      discounted_cf = annual_profit / ((1 + discount_rate)**year)
      cumulative += discounted_cf
      return year.to_f if cumulative >= 0
    end

    nil # Never pays back within horizon
  end
end
