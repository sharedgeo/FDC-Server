# frozen_string_literal: true

require 'test_helper'

class FeaturesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'
    @feature_geom = 'POINT (1 1)'
    @feature = Feature.create!(user: @user, geom: 'POINT (10 10)')
  end

  # POST /v1/features
  test 'should create features for existing user' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('Feature.count', 1) do
        post '/v1/features',
             headers: { 'Authorization' => "Bearer #{@valid_token}" },
             params: { features: [{ geom: @feature_geom }] },
             as: :json
      end
    end

    assert_response :success
    @user.reload

    assert_equal 2, Feature.where(user: @user).count
    assert Feature.exists?(user: @user, geom: @feature_geom)

    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal 'Feature(s) created successfully.', json_response['message']
  end

  test 'should return unauthorized if user does not exist' do
    new_user_email = 'new.user@example.com'
    assert_no_difference('User.count') do
      assert_no_difference('Feature.count') do
        decoded_token = { payload: { 'email' => new_user_email } }
        JsonWebToken.stub :verify, decoded_token do
          post '/v1/features',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { features: [{ geom: @feature_geom }] },
               as: :json
        end
      end
    end

    assert_response :unauthorized
  end

  test 'should return bad request if features parameter is missing' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      post '/v1/features',
           headers: { 'Authorization' => "Bearer #{@valid_token}" },
           params: {},
           as: :json
    end

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'features parameter is required.', json_response['message']
  end

  test 'should return unauthorized for invalid token when creating' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      post '/v1/features',
           headers: { 'Authorization' => "Bearer #{@invalid_token}" },
           params: { features: [{ geom: @feature_geom }] },
           as: :json
    end

    assert_response :unauthorized
  end

  test 'should return unauthorized without token when creating' do
    post '/v1/features',
         params: { features: [{ geom: @feature_geom }] },
         as: :json

    assert_response :unauthorized
  end

  # DELETE /v1/features/:id
  test 'should delete a feature for an existing user' do
    assert_difference('Feature.count', -1) do
      decoded_token = { payload: { 'email' => @user.email_address } }
      JsonWebToken.stub :verify, decoded_token do
        delete "/v1/features/#{@feature.id}",
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               as: :json
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal 'Feature deleted successfully.', json_response['message']
  end

  test 'should not delete a feature belonging to another user' do
    user_two = users(:two)
    feature_of_user_two = Feature.create!(user: user_two, geom: 'POINT (30 30)')

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('Feature.count') do
        delete "/v1/features/#{feature_of_user_two.id}",
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               as: :json
      end
    end

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'Feature not found.', json_response['message']
    assert Feature.exists?(feature_of_user_two.id)
  end

  test 'should return not found for non-existent feature id' do
    non_existent_id = Feature.last.id + 1
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('Feature.count') do
        delete "/v1/features/#{non_existent_id}",
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               as: :json
      end
    end

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'Feature not found.', json_response['message']
  end

  test 'should return unauthorized when trying to delete without token' do
    delete "/v1/features/#{@feature.id}",
           as: :json

    assert_response :unauthorized
  end
end
