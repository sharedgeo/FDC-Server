# frozen_string_literal: true

require 'test_helper'

class TicketsTest < ActionDispatch::IntegrationTest
  setup do
    @ticket = tickets(:one)
    @user = users(:one)
    @bookmark = bookmarks(:one)
  end

  def auth_headers(token = 'dummy_token')
    { 'Authorization' => "Bearer #{token}" }
  end

  test 'should get ticket as geojson with valid token' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get "/v1/tickets/#{@ticket.id}", headers: auth_headers, as: :json
      assert_response :success

      json_response = JSON.parse(response.body)
      assert_equal 'Feature', json_response['type']
      assert_not_nil json_response['geometry']
      assert_equal 'MultiPolygon', json_response['geometry']['type']
      assert_equal @ticket.ticket_no, json_response['properties']['ticket_no']
      assert_equal @ticket.ticket_type, json_response['properties']['ticket_type']
      assert_not json_response['properties'].key?('geom'), 'geom should not be in properties'
      assert_equal @bookmark.id, json_response['properties']['bookmark_id']
    end
  end

  test 'should return not found for non-existent ticket' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get '/v1/tickets/9999', headers: auth_headers, as: :json
      assert_response :not_found

      json_response = JSON.parse(response.body)
      assert_equal 'error', json_response['status']
      assert_equal 'Ticket not found', json_response['message']
    end
  end

  test 'should return unauthorized without an authorization header' do
    get "/v1/tickets/#{@ticket.id}", as: :json
    assert_response :unauthorized
  end

  test 'should return unauthorized with an invalid token' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      get "/v1/tickets/#{@ticket.id}", headers: auth_headers('invalid'), as: :json
      assert_response :unauthorized
    end
  end

  test 'should find ticket by ticket_no with valid token' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get '/v1/tickets/search', params: { ticket_no: @ticket.ticket_no }, headers: auth_headers, as: :json
      assert_response :success

      json_response = JSON.parse(response.body)
      assert_equal 'Feature', json_response['type']
      assert_equal @ticket.ticket_no, json_response['properties']['ticket_no']
      assert_equal @bookmark.id, json_response['properties']['bookmark_id']
    end
  end

  test 'should return not found for non-existent ticket_no' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get '/v1/tickets/search', params: { ticket_no: '9999' }, headers: auth_headers, as: :json
      assert_response :not_found
    end
  end

  test 'should return unauthorized for search without an authorization header' do
    get '/v1/tickets/search', params: { ticket_no: @ticket.ticket_no }, as: :json
    assert_response :unauthorized
  end
end
