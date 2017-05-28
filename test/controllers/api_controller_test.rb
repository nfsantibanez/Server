require 'test_helper'

class ApiControllerTest < ActionDispatch::IntegrationTest
  test "should get products" do
    get api_products_url
    assert_response :success
  end

  test "should get purchase_order" do
    get api_purchase_order_url
    assert_response :success
  end

  test "should get invoice" do
    get api_invoice_url
    assert_response :success
  end

  test "should get payment" do
    get api_payment_url
    assert_response :success
  end

end
