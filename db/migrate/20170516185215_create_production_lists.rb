class CreateProductionLists < ActiveRecord::Migration[5.0]
  def change
    create_table :production_lists do |t|
      t.string :sku
      t.integer :quantity

      t.timestamps
    end
  end
end
