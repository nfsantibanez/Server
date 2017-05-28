class ReorderRawMaterialsController < ApplicationController
	require 'api_controller'

	def reorder
		api = ApiController.new
	    group_number = 3  # Our group
	    raw_materials = Product.where("creator = ? AND _type = ?", group_number, 'Materia prima')
	    raw_sku = []
	    raw_materials.each do |raw_material|
	    	raw_sku.push(raw_material.sku)
	    end
	    stock = api.getStockBySku

	    render json: stock
	end
end