class CreateMachines < ActiveRecord::Migration[8.1]
  def change
    create_table :machines do |t|
      t.string :name
      t.string :model_number
      t.decimal :build_volume_x
      t.decimal :build_volume_y
      t.decimal :build_volume_z
      t.decimal :laser_power
      t.decimal :scan_speed
      t.decimal :purchase_price
      t.integer :lifespan_years
      t.decimal :annual_maintenance_cost

      t.timestamps
    end
  end
end
