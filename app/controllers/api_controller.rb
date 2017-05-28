class ApiController < ApplicationController
helper_method :gen_dashboard
require 'rest-client'
require 'base64'
require 'hmac-sha1'
require 'time'
#Para saltarnos la verificacion con token de las solicitudes
skip_before_action :verify_authenticity_token
@@warehouseKey = if Rails.env.production?
  'P;$m8Q:TaFRTSB'
else
  'tWNSSehXIl&#zO'
end
@@mode = if Rails.env.production?
  'prod'
else
  'dev'
end
@@bankID = if Rails.env.production?
  '5910c0910e42840004f6e68e'
else
  '590baa00d6b4ec000490246f'
end
MINIMUM_RAW_STOCK = 100
if Rails.env.production?
  @@id1 = '5910c0910e42840004f6e680'
  @@id2 = '5910c0910e42840004f6e681'
  @@id3 = '5910c0910e42840004f6e682'
  @@id4 = '5910c0910e42840004f6e683'
  @@id5 = '5910c0910e42840004f6e684'
  @@id6 = '5910c0910e42840004f6e685'
  @@id7 = '5910c0910e42840004f6e686'
  @@id8 = '5910c0910e42840004f6e687'
else
  @@id1 = '590baa00d6b4ec0004902462'
  @@id2 = '590baa00d6b4ec0004902463'
  @@id3 = '590baa00d6b4ec0004902464'
  @@id4 = '590baa00d6b4ec0004902465'
  @@id5 = '590baa00d6b4ec0004902466'
  @@id6 = '590baa00d6b4ec0004902467'
  @@id7 = '590baa00d6b4ec0004902468'
  @@id8 = '590baa00d6b4ec0004902469'
end
  #
  def checkRawMaterialStockLevels
    raw_skus = getRawMaterialSkus
    stock = getStockBySku
    raw_skus.each do |raw_sku|
      isntInStock = true
      if stock.size>0
        for i in 0..stock.size-1
          if stock[i]['_id'] == raw_sku
            isntInStock = false
            if stock[i]< MINIMUM_RAW_STOCK
              batch = get_batch(raw_sku)
              futureStock = stock[i]
              batches = 0
              while futureStock < MINIMUM_RAW_STOCK
                futureStock = futureStock + batch
                batches = batches +1
              end
              amount = batches*batch
              startProduction(raw_sku.to_s, amount)
            end
          end
        end
      end
      if isntInStock
        batch = get_batch(raw_sku)
        futureStock = 0
        batches = 0
        while futureStock < MINIMUM_RAW_STOCK
          futureStock = futureStock + batch
          batches = batches +1
        end
        amount = batches*batch
        startProduction(raw_sku.to_s, amount)
      end
    end
    render json: {ok: 'ok'}
  end

  def getRawMaterialSkus
    raw_materials = Product.where("creator = ? AND _type = ?", 3, 'Materia prima')
    raw_sku = []
    raw_materials.each do |raw_material|
      raw_sku.push(raw_material.sku)
    end
    return raw_sku
  end

  def getFactoryAccountNumber
    hmac = HMAC::SHA1.new(@@warehouseKey)
    string2Hash = 'GET'
    hmac.update(string2Hash)
    hash = Base64.encode64("#{hmac.digest}")
    auth = 'INTEGRACION grupo3:' + hash
    response = RestClient.get 'https://integracion-2017-'+@@mode+'.herokuapp.com/bodega/fabrica/getCuenta', {:Authorization => auth, :content_type => 'application/json'}
    parsed = JSON.parse response
    accNumber = parsed['cuentaId']
  end

  #Get prices for each prodcut
  def precios
    prices = []
    stock = getStockBySku
    products = Product.where("creator = ?", 3)
    products.each do |product|
      qty = 0
      if stock.size>0
        for i in 0..stock.size-1
          if stock[i]['_id'] == product.sku
            qty = stock[i]['total']
          end
        end
      end
      json = {sku: product.sku, precio: product.unit_production_cost, stock: qty}.to_json
      prices.push(json)
    end
    render json:prices
  end

  # Obtener listado de producto
  def products
    if true
      render json: {products: [{SKU: "", "name": "", price: 0 ,stock: 0}, {SKU: "", name: "", price: 0 ,stock: 0}]}, status: 200
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  def testQty
    getSkuQty("41")
  end

  def getSkuQty(sku)
    stock = 0
    warehouses = getWarehouses
    warehouses.each do |warehouse|
      wares = getWarehouseStock(warehouse)
      wares.each do |ware|
        if ware['_id'] == sku
          stock = stock + ware['total']
        end
      end
    end
    return stock
  end

  def show_dashboard
    render 'dashboard'
  end

  def get_prodLists
    productionLists = ProductionList.all
    render json: productionLists
  end

  def gen_dashboard
    bySku = getStockBySku
    byWarehouse = getStockByWarehouse
    @productionLists = ProductionList.all
    @gen_dashboard = {StockDisponiblePorProducto: bySku, StockDisponiblePorAlmacen: byWarehouse, ListadoOrdenesDeFabricacionEnviadas: @productionLists }
  end

  def gen_dashboard2
    bySku = getStockBySku
    byWarehouse = getStockByWarehouse
    @productionLists = ProductionList.all
    dashboard = {StockDisponiblePorProducto: bySku, StockDisponiblePorAlmacen: byWarehouse, ListadoOrdenesDeFabricacionEnviadas: @productionLists }
    render json: dashboard
  end

  def getStockByWarehouseRENDER
    r = getStockByWarehouse
    render json: r
  end

  #Get the stock in each warehouse
  def getStockByWarehouse
    warehouses = getWarehouses
    totalStock = []
    warehouses.each do |warehouse|
      wares = getWarehouseStock(warehouse)
      stock = {_id: warehouse['_id'], stock: wares}.to_json
      totalStock.push(stock)
    end
    return totalStock
  end

  def getStockBySku
    warehouses = getWarehouses
    totalStock = []
    warehouses.each do |warehouse|
      wares = getWarehouseStock(warehouse)
      wares.each do |ware|
        #check if its already on totalStock
        isOnTotalStock = false
        index=0
        if totalStock.size>0
          for i in 0..totalStock.size-1
            if totalStock[i]['_id'] == ware['_id']
              isOnTotalStock = true
              index = i
            end
          end
        end
        #Here we know if its on the list or not
        if isOnTotalStock
          totalStock[index]['total'] = totalStock[index]['total'] + ware['total']
        else
          totalStock.push(ware)
        end
      end
    end
    #render json: totalStock
    return totalStock
  end

  def get_total_stock
    response = getStockBySku
    render json: response
  end

  def getWarehouseStock(warehouse)
		hmac = HMAC::SHA1.new(@@warehouseKey)
    string2Hash = 'GET'+warehouse['_id']
    hmac.update(string2Hash)
    hash = Base64.encode64("#{hmac.digest}")
    auth = 'INTEGRACION grupo3:' + hash
    response = RestClient.get 'https://integracion-2017-'+@@mode+'.herokuapp.com/bodega/skusWithStock?almacenId='+warehouse['_id'], {:almacenId => warehouse['_id'], :Authorization => auth, :content_type => 'application/json'}
    wares = JSON.parse response
    #render json: wares
  end

  def getWarehouses
    hmac = HMAC::SHA1.new(@@warehouseKey)
    string2Hash = 'GET'
    hmac.update(string2Hash)
    hash = Base64.encode64("#{hmac.digest}")
    auth = 'INTEGRACION grupo3:' + hash
    response = RestClient.get 'https://integracion-2017-'+@@mode+'.herokuapp.com/bodega/almacenes', {:Authorization => auth, :content_type => 'application/json'}
    warehouses = JSON.parse response
    #render json: response
  end

  def checkWarehouses
    warehouses = getWarehouses()
    render json: warehouses
  end

  def prodTest
    response = startProduction('1',300)
    render json: response
  end

  def prod_leche
    response_list = []
    r1 = startProduction('41',600)
    r2 = startProduction('49',600)
    response_list.push(r1)
    response_list.push(r2)
    render json: response_list
  end

  def prod_suero
    r= startProduction('41',200)
    render json: r
  end

  def prod_descremada
    r= startProduction('49',400)
    render json: r
  end

  def produce_for_Sprint
    response_list = []
    r1 = startProduction('1',1800)
    response_list.push(r1)
    r2 = startProduction('3',1920)
    response_list.push(r2)
    r3 = startProduction('7',1000)
    response_list.push(r3)
    r4 = startProduction('9',1860)
    response_list.push(r4)
    r5 = startProduction('13',1000)
    response_list.push(r5)
    r6 = startProduction('15',1920)
    response_list.push(r6)
    #r7 = startProduction('22',2000)
    #response_list.push(r7)
    r8 = startProduction('25',1680)
    response_list.push(r8)
    #r9 = startProduction('41',2000)
    #response_list.push(r9)
    #r10 = startProduction('48',2000)
    #response_list.push(r10)
    #r11 = startProduction('49',2000)
    #response_list.push(r11)
    #r12 = startProduction('52',2670)
    #response_list.push(r12)
    render json: response_list
  end


  def moveTest
    move("590baa76d6b4ec00049026ca","590baa76d6b4ec0004902660")
  end

  def getProductTest
    getProduct("590baa76d6b4ec0004902661","41")
  end


  def payProduction(amount)
    factoryAccNumber = getFactoryAccountNumber
    response = RestClient.put 'https://integracion-2017-'+@@mode+'.herokuapp.com/banco/trx', {:monto => amount, :origen => @@bankID, :destino => factoryAccNumber}.to_json, :content_type => 'application/json'
    parsed = JSON.parse response
    id = parsed['_id']
  end

  def TestCalculatePayment
    cost = calculatePayment('13',1000)
    render json: cost
  end

  def calculatePayment(sku,quantity)
    product = Product.where("creator = ? AND sku = ?", 3, sku)
    cost = product.first.unit_production_cost*quantity
  end

  def getSaldo
    response = RestClient.get 'https://integracion-2017-'+@@mode+'.herokuapp.com/banco/cuenta/'+@@bankID,  :content_type => 'application/json'
    render json: response
  end

  def avena
    startProduction('7',1000)
  end

  #Currently not checking for a valid sku/qty ratio
  # sku is supposed to be a string & qty an integer
  def startProduction(sku,quantity)
    price = calculatePayment(sku,quantity)
    trx = payProduction(price)
    hmac = HMAC::SHA1.new(@@warehouseKey)
    string2Hash = 'PUT'+sku+quantity.to_s+trx
    hmac.update(string2Hash)
    hash = Base64.encode64("#{hmac.digest}")
    auth = 'INTEGRACION grupo3:' + hash
    response = RestClient.put 'https://integracion-2017-'+@@mode+'.herokuapp.com/bodega/fabrica/fabricar', {:trxId => trx, :sku => sku, :cantidad => quantity}.to_json, :Authorization => auth, :content_type => 'application/json'
    productionList = ProductionList.create(sku: sku, quantity: quantity)
    return response
  end

  def reorder_processed_material
    response_list = []
    group_number = 3  # Our group
    processed_materials = Product.where("creator = ? AND _type = ?", group_number, 'Producto procesado')
    processed_sku = []
    processed_materials.each do |processed_material|
      processed_sku.push(processed_material.sku)
    end
    stock = getStockBySku
    processed_stock = []
    stock.each do |stk|
      if processed_stock.include? stk['_id']
        processed_stock.push(stk)
      end
    end
    processed_sku.each do |psku|
      quantity = 0
      processed_stock.each do |pstk|
        if pstk['_id'] == psku
          quantity = pstk['total']
        end
      end
      minimum_level = get_minimum_level(psku, false)
      if quantity < minimum_level
        # We have to check if we have the raw materials to produce
        batch =  get_batch(psku)  # Right now we are always ordering the minimum quantity
        response = startProduction(psku, batch)
        response_list.push(response)
      end
    end
    render json: response_list
  end

  def reorder_raw_material
    response_list = []
    group_number = 3  # Our group
    raw_materials = Product.where("creator = ? AND _type = ?", group_number, 'Materia prima')
    raw_sku = []
    raw_materials.each do |raw_material|
      raw_sku.push(raw_material.sku)
    end
    stock = getStockBySku
    raw_stock = []
    stock.each do |stk|
      if raw_sku.include? stk['_id']
        raw_stock.push(stk)
      end
    end
    raw_sku.each do |rsku|
      quantity = 0
      raw_stock.each do |rstk|
        if rstk['_id'] == rsku
          quantity = rstk['total']
        end
      end
      minimum_level = get_minimum_level(rsku, true)
      if quantity < minimum_level
        batch = get_batch(rsku)  # Right now we are always ordering the minimum quantity
        response = startProduction(rsku, batch)
        response_list.push(response)
      end
    end
    render json: response_list
  end

  def get_batch(sku)
    batch = Product.where("sku = ?", sku).take.batch
    return batch
  end

  def get_minimum_level(sku, is_raw)
    # It should return the minimum inventory level for a specific sku (with a switch statement)
    if is_raw
      return 1999
    else
      return 399
    end
  end

  def getProduct(warehouse_id,sku)
    hmac = HMAC::SHA1.new(@@warehouseKey)
    string2Hash = 'GET'+warehouse_id+sku
    hmac.update(string2Hash)
    hash = Base64.encode64("#{hmac.digest}")
    auth = 'INTEGRACION grupo3:' + hash
    response = RestClient.get 'https://integracion-2017-'+@@mode+'.herokuapp.com/bodega/stock?almacenId='+warehouse_id+'&sku='+sku, :Authorization => auth, :content_type => 'application/json'
    products = JSON.parse response
  end

  def moveMilk
    moveSku('7',80,'5910c0b90e42840004f6e8a3','5910c0b90e42840004f6e773')
  end


  def moveSku(sku,qty,origin_id, destination_id)
    products = getProduct(origin_id,sku)
    for i in 0..qty-1 do
     move(products[i]['_id'],destination_id)
    end
    render json: 'ok'
  end

  def move(product_id,warehouse_id)
    hmac = HMAC::SHA1.new(@@warehouseKey)
    string2Hash = 'POST'+product_id+warehouse_id
    hmac.update(string2Hash)
    hash = Base64.encode64("#{hmac.digest}")
    auth = 'INTEGRACION grupo3:' + hash
    response = RestClient.post 'https://integracion-2017-'+@@mode+'.herokuapp.com/bodega/moveStock', {:productoId => product_id, :almacenId => warehouse_id}.to_json, :Authorization => auth, :content_type => 'application/json'
  end

  def delivery(product_id,warehouse_id,oc_id,price)
    hmac = HMAC::SHA1.new(@@warehouseKey)
    string2Hash = 'POST'+product_id+warehouse_id
    hmac.update(string2Hash)
    hash = Base64.encode64("#{hmac.digest}")
    auth = 'INTEGRACION grupo3:' + hash
    response = RestClient.post 'https://integracion-2017-'+@@mode+'.herokuapp.com/bodega/moveStockBodega', {:productoId => product_id, :almacenId => warehouse_id, :oc => oc_id, :precio => price}.to_json, :Authorization => auth, :content_type => 'application/json'
  end

  def createOc(client_id, supplier_id, sku, delivery_date, quantity, price, channel, notes)
      response = RestClient.put 'https://integracion-2017-'+@@mode+'.herokuapp.com/oc/crear', {:cliente => client_id,:proveedor => supplier_id, :sku => sku, :fechaEntrega => delivery_date, :cantidad => quantity, :precioUnitario => price, :canal => channel, :notas => notes}.to_json, :content_type => 'application/json'
      r = JSON.parse response
      oc = Oc.create(cliente: r['cliente'],proveedor: r['proveedor'],notas: r['notas'],sku: r['sku'],_id: r['_id'],estado: r['estado'], fechaEntrega: r['fechaEntrega'],precioUnitario: r['precioUnitario'],cantidad: r['cantidad'], cantidadDespachada: r['cantidadDespachada'], canal: r['canal'])
      return r
  end

  def sendOc(clientNumber,oc_id)
    #r = {:payment_method => 'contado', :payment_option => '0'}.to_json
    response = RestClient.put 'http://integra17-'+clientNumber+'.ing.puc.cl/api/put_purchase_orders/:'+oc_id, {:payment_method => 'contado', :payment_option => '0'}.to_json, :content_type => 'application/json'
    render json:response
  end

  def buyEggs
    oc = createOc(@@id3, @@id2,2,1893214596281,180,102, "b2b", "a")
    sendOc('2',oc['_id'])
  end

  def test_oc_obtener
    get_purchase_order("591a2cc6ea37b2000403c82e")
  end

  def get_purchase_order(purchase_order_id)
    #obtengo la orden de compra
    response = RestClient.get 'https://integracion-2017-dev.herokuapp.com/oc/obtener/'+purchase_order_id, :content_type => 'application/json'
    if true
      #acepto la orden de compra
      response2 = RestClient.post 'https://integracion-2017-dev.herokuapp.com/oc/recepcionar/'+ purchase_order_id, {:_id => purchase_order_id}.to_json, :content_type => 'application/json'
    else
      #rechazo la orden de compra
      response2 = RestClient.post 'https://integracion-2017-dev.herokuapp.com/oc/rechazar/'+ purchase_order_id, {:_id => purchase_order_id, :rechazo => "Rechazado por stock"}.to_json, :content_type => 'application/json'
    end
    render json: response2
  end

  # Enviar nueva orden de compra (realizar pedido)
  def put_purchase_order
    #orden = purchase_order_params
    if true
      mensaje = {id: params[:id], payment: "", payment_option: 0, id_negotiation: 0}
      render json: mensaje, status: 202
    elsif false
      render json: {error: "La creación de la orden de compra ha fallado"}, status: 500
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar aceptación orden de compra
  def post_purchase_order
    #id = params[:id]
    if true
      render json: {}, status: 204
    elsif false
      render json: {error: "id de la orden de compra no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar rechazo orden de compra
  def delete_purchase_order
    #rechazo = reject_params
    #id = params[:id]
    if true
      render json: {}, status: 204
    elsif false
      render json: {error: "id de la orden de compra no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar anulación de orden de compra
  def patch_purchase_order
    #anulación = cancel_params
    #id = params[:id]
    if true
      render json: {}, status: 204
    elsif false
      render json: {error: "id de la orden de compra no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Emitir nueva factura
  def put_invoice
    if true
      mensaje = {id_bill: params[:id], id_purchase_order: 0}
      render json: mensaje, status: 202
    elsif false
      render json: {error: "La emisión de la factura ha fallado"}, status: 500
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar aceptación de factura
  def post_invoice
    #id = params[:id]
    if true
      render json: {}, status: 204
    elsif false
      render json: {error: "id de la factura no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar rechazo de factura
  def delete_invoice
    #rechazo = reject_params
    #id = params[:id]
    if true
      render json: {}, status: 204
    elsif false
      render json: {error: "id de la factura no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar de pago de factura
  def put_payment
    #pay = payment_params
    if true
      render json: {}, status: 204
    elsif false
      render json: {error: "id de la factura o transacción no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Crear notificación de despacho de productos
  def put_delivered
    #despacho = deliver_params
    if true
      mensaje = {id_purchase_order: params[:id], datetime: 0}
      render json: mensaje, status: 202
    elsif false
      render json: {error: "La creación del despacho ha fallado"}, status: 500
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar aceptación del despacho
  def post_delivered
    #id = params[:id]
    if true
      render json: {}, status: 204
    elsif false
      render json: {error: "id del despacho no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar rechazo del despacho
  def delete_delivered
    #rechazo = reject_params
    #id = params[:id]
    if true
      render json: {}, status: 204
    elsif false
      render json: {error: "id de la factura no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Crear propuesta de negociacion
  def put_negotiation
    #negociacion = negotiation_params
    if true
      mensaje = {id_negotiation: 0, note: ""}
      render json: mensaje, status: 202
    elsif false
      render json: {error: "El envío de la propuesta de negociación ha fallado"}, status: 500
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar aceptación de la negociacion
  def post_negotiation
    #id = params[:id]
    if true
      render json: {}, status: 204
    elsif false
      render json: {observation: ""}, status: 100
    elsif false
      render json: {error: "id de la negociación no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Informar rechazo de la negociacion
  def delete_negotiation
    #rechazo = reject_params
    #id = params[:id]
    if true
      render json: {}, status: 204
    elsif false
      render json: {error: "id de la negociación no existe"}, status: 404
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  # Obtener cuenta para pagar a la empresa
  def account
    if true
      render json: {account: ""}, status: 200
    elsif false
      render json: {error: "La autenticación ha fallado"}, status: 401
    end
  end

  private

    #Definir los parametro que son permitidos para crear orden de compra
    def purchase_order_params
     params.permit(:payment, :payment_option, :id_negotiation)
    end

    #Definir parametros que son permitidos para informar pago de factura
    def payment_params
      params.permit(:id_transaction)
    end

    #Definir parametros que son permitidos para informar despacho de productos
    def deliver_params
      params.permit(:id_purchase_order, :datetime)
    end

    #Definir parametros que son permitidos para enviar negociacion
    def negotiation_params
      params.permit(:note)
    end

    #Definir parametros para nota de rechazo
    def reject_params
      params.permit(:reject, :newdate)
    end

    #Definir parametros para nota de anulacion
    def cancel_params
      params.permit(:cancel)
    end



end
