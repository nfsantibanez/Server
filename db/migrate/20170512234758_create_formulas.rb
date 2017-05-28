class CreateFormulas < ActiveRecord::Migration[5.0]
  def change
    create_table :formulas do |t|
      t.string :sku
      t.string :description
      t.string :unit
      t.string :ingredient_sku
      t.integer :requirement
      t.string :ingredient_unit

      t.timestamps
    end
  end
end
