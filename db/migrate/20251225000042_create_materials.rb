class CreateMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :materials do |t|
      t.string :name
      t.string :code
      t.decimal :density
      t.decimal :raw_material_price
      t.decimal :embodied_carbon
      t.decimal :recycling_efficiency

      t.timestamps
    end
  end
end
