class ECommerceController < ApplicationController
  require 'openssl'
  require 'base64'
  require 'rest-client'

  def update_products
    #key bodega_desarrollo
    key_d= 'tWNSSehXIl&#zO'
    #key bodega_produccion
    key_p= 'P;$m8Q:TaFRTSB'

    #parametros para obtener almacenes
    par = 'GET'
    #Construccion autenticacion
    hash  = Base64.encode64(OpenSSL::HMAC.digest('sha1', key_d, par))
    auth = 'INTEGRACION grupo3:'+hash
    #Llamada a API profesor
    response = RestClient.get 'https://integracion-2017-dev.herokuapp.com/bodega/almacenes/', :Authorization => auth, :content_type => 'application/json'
    almacenes = JSON.parse response

    #Encontrar bodega de recepcion
    for almacen in almacenes
      if almacen["recepcion"] == true
        id_recep =  almacen["_id"]
      end
    end

    #parametros para obtener cantidades de los producto del almacen de recepcion
    par= 'GET'+id_recep
    #Construccion autenticacion
    hash  = Base64.encode64(OpenSSL::HMAC.digest('sha1', key_d, par))
    auth = 'INTEGRACION grupo3:'+hash
    #Llamada a API profesor
    response = RestClient.get 'https://integracion-2017-dev.herokuapp.com/bodega/skusWithStock?almacenId='+id_recep, :Authorization => auth, :content_type => 'application/json'
    productos = JSON.parse response

    #Hash que relaciona sku del producto con el stock_item_id
    stock= {"1": "36", "3": "37", "7": "38", "9": "39", "13": "40", "15": "41",
      "22": "27", "25": "42", "41": "28", "48": "29", "49": "30", "52": "34"}

    #cargar productos de bogeda a e-commerce
    #token del administrador del e-commerce
    token = '?token=074faa0472eab121b4d2ff4b474c12e3c5288126e40886c2'
    #Enviar cambios a API del e-commerce para cargar productos de bodega
    for p in productos
      #HAY QUE CAMBIAR URL DEL SERVER Y NO LOCAL DESPUES
      response = RestClient.put 'http://localhost:3000/e-commerce/api/v1/stock_locations/1/stock_items/'+p["_id"]+token, {:stock_item => {"count_on_hand" => p["total"], "force" => true}}.to_json, :content_type => 'application/json'
    end

    render text: productos
  end

  def update_products2
    token = '&token=074faa0472eab121b4d2ff4b474c12e3c5288126e40886c2'
    param1 = '?stock_item[count_on_hand]='
    param2 = '&stock_item[force]=true'
    id = '29'
    cant = '550'
    response = RestClient.put 'http://localhost:3000/e-commerce/api/v1/stock_locations/1/stock_items/'+id+param1+cant+param2+token, {}, :content_type => 'application/json'
    render json: response
  end

end
