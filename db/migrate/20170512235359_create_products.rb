class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :sku
      t.string :description
      t.string :_type
      t.integer :creator
      t.string :unit
      t.float :unit_production_cost
      t.integer :batch
      t.integer :ingredients_number
      t.integer :dependents
      t.float :production_time

      t.timestamps
    end
  end
end
