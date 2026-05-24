class AddGlobalParamsToSlicingDatum < ActiveRecord::Migration[8.1]
  def change
    change_table :slicing_data do |t|
      # Maintenance
      t.decimal :preventive_maintenance_frequency, default: 4, precision: 10, scale: 0
      t.decimal :preventive_maintenance_cost, default: 5000.0, precision: 10, scale: 2
      t.decimal :corrective_maintenance_frequency, default: 2, precision: 10, scale: 0
      t.decimal :corrective_maintenance_cost, default: 12_000.0, precision: 10, scale: 2
    end
  end
end
