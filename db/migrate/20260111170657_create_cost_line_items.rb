class CreateCostLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cost_line_items do |t|
      t.references :slicing_datum, null: false, foreign_key: true
      t.string :category, null: false # labor, consumables, energy, equipment, facility, digital, maintenance
      t.string :name, null: false
      t.text :description
      t.decimal :unit_cost, precision: 15, scale: 2, null: false
      t.decimal :quantity, precision: 15, scale: 4, null: false, default: 1.0
      t.string :unit_type # hours, kg, kWh, per_build, etc.
      t.decimal :total_cost, precision: 15, scale: 2
      t.boolean :is_per_build, default: true # true = per build, false = per part
      t.integer :position # for ordering

      t.timestamps
    end

    add_index :cost_line_items, %i[slicing_datum_id category]
    add_index :cost_line_items, :category
  end
end
