class CreateOcs < ActiveRecord::Migration[5.0]
  def change
    create_table :ocs do |t|
      t.string :cliente
      t.string :proveedor
      t.string :notas
      t.string :sku
      t.string :_id
      t.string :estado
      t.string :fechaEntrega
      t.string :precioUnitario
      t.integer :cantidadDespachada
      t.integer :cantidad
      t.string :canal

      t.timestamps
    end
  end
end
