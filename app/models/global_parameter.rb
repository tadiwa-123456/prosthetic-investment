class GlobalParameter < ApplicationRecord
  validates :electricity_rate, :labor_rate, :annual_operating_hours,
            presence: true, numericality: { greater_than: 0 }

  # Financial parameter validations
  validates :price_per_part, presence: true, numericality: { greater_than: 0 }
  validates :discount_rate, presence: true, numericality: { greater_than: 0, less_than: 1 }
  validates :analysis_horizon_years, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :upfront_investment, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :machine_utilization_rate, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 1 }
  validates :minimum_acceptable_return, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Singleton pattern - only one set of global parameters
  def self.current
    first_or_create do |param|
      # Set defaults if creating for the first time
      param.price_per_part ||= 1000.0
      param.discount_rate ||= 0.10
      param.analysis_horizon_years ||= 5
      param.upfront_investment ||= 5_000_000.0
      param.machine_utilization_rate ||= 0.75
      param.minimum_acceptable_return ||= 15.0
      param.cost_volatility ||= 0.10
      param.revenue_volatility ||= 0.10
      param.monte_carlo_iterations ||= 10_000
    end
  end

  def facility_cost_per_hour
    (annual_rent + annual_utilities + annual_admin) / annual_operating_hours
  end

  def digital_cost_per_hour
    (annual_software_cost + annual_hpc_cost) / annual_operating_hours
  end

  def total_annual_maintenance
    (preventive_maintenance_frequency * preventive_maintenance_cost) +
      (corrective_maintenance_frequency * corrective_maintenance_cost)
  end
end
