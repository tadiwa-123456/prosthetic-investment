class CreateSlicingData < ActiveRecord::Migration[8.1]
  def change
    create_table :slicing_data do |t|
      t.string :part_name
      t.decimal :part_volume
      t.decimal :part_height
      t.decimal :surface_area
      t.decimal :support_volume
      t.decimal :layer_thickness
      t.string :csv_file

      t.timestamps
    end
  end
end
