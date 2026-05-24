class Machine < ApplicationRecord
  has_many :slicing_data, dependent: :restrict_with_error

  validates :name, presence: true
  validates :model_number, presence: true, uniqueness: true
  validates :build_volume_x, :build_volume_y, :build_volume_z,
            presence: true, numericality: { greater_than: 0 }
  validates :laser_power, :scan_speed,
            presence: true, numericality: { greater_than: 0 }
  validates :purchase_price, :annual_maintenance_cost,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :lifespan_years,
            presence: true, numericality: { greater_than: 0, only_integer: true }

  def build_volume
    build_volume_x * build_volume_y * build_volume_z
  end

  def hourly_rate(annual_operating_hours = 2000)
    # Machine hourly rate = (Purchase + Annual Maintenance) / Annual Hours
    (purchase_price / lifespan_years + annual_maintenance_cost) / annual_operating_hours
  end
end
