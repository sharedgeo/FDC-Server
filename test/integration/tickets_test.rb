require "test_helper"

class TicketsTest < ActionDispatch::IntegrationTest
  setup do
    @ticket = tickets(:one)
    @user = users(:one)
  end

  def auth_headers(token = "dummy_token")
    { "Authorization" => "Bearer #{token}" }
  end

  test "should get ticket as geojson with valid token" do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get "/v1/tickets/#{@ticket.ticket_no}", headers: auth_headers, as: :json
      assert_response :success

      json_response = JSON.parse(response.body)
      assert_equal "Feature", json_response["type"]
      assert_not_nil json_response["geometry"]
      assert_equal "MultiPolygon", json_response["geometry"]["type"]
      assert_equal @ticket.ticket_no, json_response["properties"]["ticket_no"]
      assert_equal @ticket.ticket_type, json_response["properties"]["ticket_type"]
      assert_not json_response["properties"].key?("geom"), "geom should not be in properties"
    end
  end

  test "should return not found for non-existent ticket" do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get "/v1/tickets/NON-EXISTENT-TICKET", headers: auth_headers, as: :json
      assert_response :not_found

      json_response = JSON.parse(response.body)
      assert_equal "error", json_response["status"]
      assert_equal "Ticket not found", json_response["message"]
    end
  end

  test "should return unauthorized without an authorization header" do
    get "/v1/tickets/#{@ticket.ticket_no}", as: :json
    assert_response :unauthorized
  end

  test "should return unauthorized with an invalid token" do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError.new("Invalid token") } do
      get "/v1/tickets/#{@ticket.ticket_no}", headers: auth_headers("invalid"), as: :json
      assert_response :unauthorized
    end
  end
end
