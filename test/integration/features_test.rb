# frozen_string_literal: true

require 'test_helper'

class FeaturesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @ticket = tickets(:one)
    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'
    @feature_geom = { type: 'MultiPolygon', coordinates: [[[[1.0, 1.0], [2.0, 2.0], [3.0, 3.0], [1.0, 1.0]]]] }
    @feature = Feature.create!(user: @user, ticket: @ticket, geom: 'MULTIPOLYGON (((10 10, 20 20, 30 30, 10 10)))')
  end

  # POST /v1/features
  test 'should create a feature for an existing user and ticket' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('Feature.count', 1) do
        post '/v1/features',
             headers: { 'Authorization' => "Bearer #{@valid_token}" },
             params: { feature: { ticket_id: @ticket.id, geom: @feature_geom } },
             as: :json
      end
    end

    assert_response :created
    feature = Feature.last
    assert_equal @user, feature.user
    assert_equal @ticket, feature.ticket
    assert_equal @feature_geom.to_json, RGeo::GeoJSON.encode(feature.geom).to_json

    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal 'Feature created successfully.', json_response['message']
    assert_not_nil json_response['feature_id']
  end

  test 'should create user and feature if user does not exist' do
    new_user_email = 'new.user@example.com'
    decoded_token = { payload: { 'email' => new_user_email } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('User.count', 1) do
        assert_difference('Feature.count', 1) do
          post '/v1/features',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { feature: { ticket_id: @ticket.id, geom: @feature_geom } },
               as: :json
        end
      end
    end

    assert_response :created
    new_user = User.find_by(email_address: new_user_email)
    assert new_user
    assert(new_user.features.any? { |f| f.geom.as_text == RGeo::GeoJSON.decode(@feature_geom.to_json).as_text })
  end

  test 'should return bad request if geom parameter is missing' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      post '/v1/features',
           headers: { 'Authorization' => "Bearer #{@valid_token}" },
           params: { feature: { ticket_id: @ticket.id } },
           as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'Validation failed: Geom can\'t be blank', json_response['message']
  end

  test 'should return unauthorized for invalid token when creating' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      post '/v1/features',
           headers: { 'Authorization' => "Bearer #{@invalid_token}" },
           params: { feature: { ticket_id: @ticket.id, geom: @feature_geom } },
           as: :json
    end

    assert_response :unauthorized
  end

  test 'should return unauthorized without token when creating' do
    post '/v1/features',
         params: { feature: { ticket_id: @ticket.id, geom: @feature_geom } },
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
    feature_of_user_two = Feature.create!(user: user_two, ticket: @ticket,
                                          geom: 'MULTIPOLYGON (((30 30, 40 40, 50 50, 30 30)))')

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
    non_existent_id = Feature.maximum(:id) + 1
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('Feature.count') do
        delete "/v1/features/#{non_existent_id}",
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               as: :json
      end
    end

    assert_response :not_found
  end

  test 'should return unauthorized when trying to delete without token' do
    delete "/v1/features/#{@feature.id}",
           as: :json

    assert_response :unauthorized
  end
end
