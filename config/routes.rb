Rails.application.routes.draw do

  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the :at option to something different.
  #
  # We ask that you don't use the :as option here, as Spree relies on it being the default of "spree"
  mount Spree::Core::Engine, at: '/e-commerce'

  #
  get 'e' => 'e_commerce#update_products2'

  #Temporal
  get 'api/dashboard' => 'api#show_dashboard'
  get 'moveMilk' => 'api#moveMilk'
  get 'suero'=> 'api#prod_suero'
  get 'descremada'=> 'api#prod_descremada'
  get 'dashboard' => 'api#gen_dashboard'
  get 'almacenes' => 'api#checkWarehouses'
  get 'stockPorAlmacen' => 'api#getStockByWarehouseRENDER'
  get 'stockPorSku' => 'api#get_total_stock'
  get 'stockSku' => 'api#testQty'
  get 'api/prodTest' => 'api#prodTest'
  get 'move' => 'api#moveTest'
  get 'prodTest' => 'api#getProductTest'
  get 'api/test' => 'api#reorder_raw_material'
  get 'api/test2' => 'api#reorder_processed_material'
  get 'api/test3' => 'api#prodTest'
  get 'api/test4' => 'api#get_total_stock'
  get 'api/produce' => 'api#produce_for_Sprint'
  get 'api/test_oc' => 'api#test_oc'
  get 'api/test_oc_obtener' => 'api#test_oc_obtener'
  get 'api/milk' => 'api#prod_leche'
  get 'api/50ocs' => 'api#generate50ocs'
  get 'api/publico/precios' => 'api#precios'
  get 'stock' => 'api#checkRawMaterialStockLevels'
  get 'f' => 'api#getFactoryAccountNumber'
  get 'dash2' => 'api#gen_dashboard2'
  get 'avena' => 'api#buyEggs'

  #Productos
  get 'api/products/' => 'api#products'

  #Ordenes de compra
  put 'api/purchase_order/:id' => 'api#put_purchase_order', :defaults => { :format => :json }
  post 'api/purchase_order/:id' => 'api#post_purchase_order'
  delete 'api/purchase_order/:id' => 'api#delete_purchase_order', :defaults => { :format => :json }
  patch 'api/purchase_order/:id' => 'api#patch_purchase_order', :defaults => { :format => :json }

  #Facturas
  put 'api/invoice/:id' => 'api#put_invoice', :defaults => { :format => :json }
  post 'api/invoice/:id' => 'api#post_invoice'
  delete 'api/invoice/:id' => 'api#delete_invoice', :defaults => { :format => :json }
  put 'api/payment/' => 'api#put_payment', :defaults => { :format => :json }

  #Despacho Productos
  put 'api/delivered/:id' => 'api#put_delivered', :defaults => { :format => :json }
  post 'api/delivered/:id' => 'api#post_delivered'
  delete 'api/delivered/:id' => 'api#delete_delivered', :defaults => { :format => :json }

  #Negociacion
  put 'api/negotiation/' => 'api#put_negotiation', :defaults => { :format => :json }
  post 'api/negotiation/:id' => 'api#post_negotiation'
  delete 'api/negotiation/:id' => 'api#delete_negotiation', :defaults => { :format => :json }

  #Cuenta bancaria
  get 'api/account/' => 'api#account'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
