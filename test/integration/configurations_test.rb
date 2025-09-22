# test/integration/configurations_test.rb

require 'test_helper'

class ConfigurationsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'
  end

  test 'should show configuration with feature_classes' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get '/v1/configuration', headers: { 'Authorization' => "Bearer #{@valid_token}" }, as: :json
    end

    assert_response :ok

    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']

    data = json_response['data']
    assert_not_nil data['feature_classes']
    assert data['feature_classes'].is_a?(Array)

    # Check that feature_classes contain expected attributes
    if data['feature_classes'].any?
      feature_class = data['feature_classes'].first
      assert feature_class.key?('id')
      assert feature_class.key?('code')
      assert feature_class.key?('name')
      assert feature_class.key?('color_mapserv')
      assert feature_class.key?('color_hex')
    end
  end

  test 'should return unauthorized without token' do
    get '/v1/configuration', as: :json
    assert_response :unauthorized
  end

  test 'should return unauthorized with invalid token' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      get '/v1/configuration', headers: { 'Authorization' => "Bearer #{@invalid_token}" }, as: :json
    end
    assert_response :unauthorized
  end

  test 'should create user and show configuration if user does not exist' do
    new_user_email = 'new.user@example.com'
    decoded_token = { payload: { 'email' => new_user_email } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference 'User.count', 1 do
        get '/v1/configuration', headers: { 'Authorization' => "Bearer #{@valid_token}" }, as: :json
      end
    end
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    data = json_response['data']
    assert_not_nil data['feature_classes']
  end
end