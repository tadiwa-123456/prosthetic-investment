class Material < ApplicationRecord
  has_many :slicing_data, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :density, presence: true, numericality: { greater_than: 0 }
  validates :raw_material_price, presence: true, numericality: { greater_than: 0 }
  validates :embodied_carbon, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :recycling_efficiency,
            presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 1 }
end
