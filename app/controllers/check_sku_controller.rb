class CheckSkuController < ApplicationController
	require 'rest-client'
	require 'base64'
	require 'hmac-sha1'

	# Lo que esta pasando:
	# Quiero tener una lista con todos los id's de almacenes.
	# result (el get de almacenes) me entrega un string con
	# todos los almacenes. Tengo que extraer el _id del almacen
	# de este string para agregarlo a la lista anterior.
	# Luego voy a poder chequear el stock. La razon de borrar es para ver
	# que me retorna el get. Es un metodo temporal que sera eliminado.
	# Al parecer JSON.parse(string) resuelve mi problema.

	def borrar
	    warehouseKey = 'tWNSSehXIl&#zO'
	    hmac = HMAC::SHA1.new(warehouseKey)
	    string2Hash = 'GET'
	    hmac.update(string2Hash)
	    hash = Base64.encode64("#{hmac.digest}")
	    auth = 'INTEGRACION grupo3:' + hash
	    result = RestClient.get 'https://integracion-2017-dev.herokuapp.com/bodega/almacenes', {:Authorization => auth, :content_type => 'application/json'}
	    render json: result.body.to_json
	end


	def check_stock
	    warehouseKey = 'tWNSSehXIl&#zO'
	    hmac = HMAC::SHA1.new(warehouseKey)
	    string2Hash = 'GET'
	    hmac.update(string2Hash)
	    hash = Base64.encode64("#{hmac.digest}")
	    auth = 'INTEGRACION grupo3:' + hash
	    result = RestClient.get 'https://integracion-2017-dev.herokuapp.com/bodega/almacenes', {:Authorization => auth, :content_type => 'application/json'}
	    warehouses = []
	    for index in 0.. (result.body.size-1)
	    	warehouses.push(result.body[index]._id)
	    end
	    render json: warehouses.to_json
	    return
	    group_number = 3  # Our group
	    raw_materials = Product.where("creator = ? AND _type = ?", group_number, 'Materia prima')
	    raw_sku = []
	    for index in 0.. (raw_materials.size-1)
	    	raw_sku.push(raw_materials[index].sku)
	    end
	    prueba = []
	    for index in 0.. (warehouses.size-1)
	    	warehouse_id = warehouses[index]
	    	hmac2 = HMAC::SHA1.new(warehouseKey)
	    	string2Hash2 = 'GET' + warehouse_id
	    	hmac2.update(string2Hash2)
	    	hash2 = Base64.encode64("#{hmac.digest}")
	    	auth2 = 'INTEGRACION grupo3:' + hash
	    	products = RestClient.get 'https://integracion-2017-dev.herokuapp.com/bodega/skusWithStock', {:almacenId => warehouse_id, :Authorization => auth, :content_type => 'application/json'}
	    	prueba.push(products)
	    end
	    render json: prueba.to_json
	end

 #Returns an array of JSON objects with the qtys of the skus in each warehouse
 #OBSOLETE, CHECK getStockByWarehouse METHOD IN THE API CONTROLLER
	def check_stock2
		totalStock = []
		warehouseKey = 'tWNSSehXIl&#zO'
		hmac = HMAC::SHA1.new(warehouseKey)
		string2Hash = 'GET'
		hmac.update(string2Hash)
		hash = Base64.encode64("#{hmac.digest}")
		auth = 'INTEGRACION grupo3:' + hash
		response = RestClient.get 'https://integracion-2017-dev.herokuapp.com/bodega/almacenes', {:Authorization => auth, :content_type => 'application/json'}
		almacenes = JSON.parse response
		almacenes.each do |almacen|
			string2Hash = 'GET'+almacen['_id']
			hmac.update(string2Hash)
			hash = Base64.encode64("#{hmac.digest}")
			auth = 'INTEGRACION grupo3:' + hash
			response = RestClient.get 'https://integracion-2017-dev.herokuapp.com/bodega/skusWithStock?almacenId='+almacen['_id'], {:almacenId => almacen['_id'], :Authorization => auth, :content_type => 'application/json'}
			stockAlmacen = JSON.parse response
			stockAlmacen.each do |stock|
				totalStock.push(stock)
			end
		end
		render json: totalStock
	end

	def get_minimum_level(sku)
		return 2000  # It should return the minimum inventory level for a specific sku (with a switch statement)
	end
end
