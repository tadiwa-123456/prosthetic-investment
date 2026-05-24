# app/models/cost_line_item.rb
class CostLineItem < ApplicationRecord
  belongs_to :slicing_datum

  # Only the four allowed cost drivers are valid.
  CATEGORIES = %w[
    labor
    consumables
    energy
    equipment
  ].freeze

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :name, presence: true
  validates :unit_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  before_validation :calculate_total_cost

  scope :by_category, ->(category) { where(category: category) }
  scope :labor_items, -> { where(category: "labor") }
  scope :consumable_items, -> { where(category: "consumables") }
  scope :energy_items, -> { where(category: "energy") }
  scope :equipment_items, -> { where(category: "equipment") }
  scope :facility_items, -> { where(category: "facility") }
  scope :digital_items, -> { where(category: "digital") }
  scope :maintenance_items, -> { where(category: "maintenance") }
  scope :ordered, -> { order(:position, :created_at) }

  # Category display names
  CATEGORY_NAMES = {
    "labor" => "Labor",
    "consumables" => "Material",
    "energy" => "Energy",
    "equipment" => "Equipment"
  }.freeze

  def category_name
    CATEGORY_NAMES[category] || category.titleize
  end

  def total_per_part
    is_per_build ? total_cost / slicing_datum.parts_per_build : total_cost
  end

  def total_per_build
    is_per_build ? total_cost : total_cost * slicing_datum.parts_per_build
  end

  private

  def calculate_total_cost
    self.total_cost = unit_cost * quantity
  end
end
