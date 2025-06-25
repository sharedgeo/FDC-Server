# frozen_string_literal: true

require 'test_helper'

class UsersFeaturesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'
    @new_user_email = 'new.user@example.com'
    @feature_geom = 'POINT (1 1)'
    @feature = Feature.create!(user: @user, geom: 'POINT (10 10)')
  end

  test 'should create features for existing user' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('Feature.count', 1) do
        post '/user/features',
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
    assert_equal @user.id, json_response['data']['id']
    assert_equal 2, json_response['data']['features'].count
    assert_includes json_response['data']['features'].map { |f| f['geom'] }, @feature_geom
  end

  test 'should create user and features if user does not exist' do
    assert_difference('User.count', 1) do
      assert_difference('Feature.count', 1) do
        decoded_token = { payload: { 'email' => @new_user_email } }
        JsonWebToken.stub :verify, decoded_token do
          post '/user/features',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { features: [{ geom: @feature_geom }] },
               as: :json
        end
      end
    end

    assert_response :success
    new_user = User.find_by(email_address: @new_user_email)
    assert new_user
    assert_equal 1, Feature.where(user: new_user).count
  end

  test 'should return bad request if features parameter is missing' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      post '/user/features',
           headers: { 'Authorization' => "Bearer #{@valid_token}" },
           params: {},
           as: :json
    end

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'features parameter is required and must be an array of feature objects.',
                 json_response['message']
  end

  test 'should return unauthorized for invalid token' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      post '/user/features',
           headers: { 'Authorization' => "Bearer #{@invalid_token}" },
           params: { features: [{ geom: @feature_geom }] },
           as: :json
    end

    assert_response :unauthorized
  end

  test 'should return unauthorized without token' do
    post '/user/features',
         params: { features: [{ geom: @feature_geom }] },
         as: :json

    assert_response :unauthorized
  end

  # Tests for DELETE /user/features
  test 'should delete a single feature for an existing user' do
    assert_difference('Feature.count', -1) do
      decoded_token = { payload: { 'email' => @user.email_address } }
      JsonWebToken.stub :verify, decoded_token do
        delete '/user/features',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { feature_ids: [@feature.id] },
               as: :json
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '1 feature(s) deleted successfully.', json_response['message']
  end

  test 'should delete multiple features for an existing user' do
    feature2 = Feature.create!(user: @user, geom: 'POINT (20 20)')
    assert_equal 2, @user.features.count

    assert_difference('Feature.count', -2) do
      decoded_token = { payload: { 'email' => @user.email_address } }
      JsonWebToken.stub :verify, decoded_token do
        delete '/user/features',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { feature_ids: [@feature.id, feature2.id] },
               as: :json
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '2 feature(s) deleted successfully.', json_response['message']
  end

  test 'should not delete a feature belonging to another user' do
    user_two = users(:two)
    feature_of_user_two = Feature.create!(user: user_two, geom: 'POINT (30 30)')

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('Feature.count') do
        delete '/user/features',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { feature_ids: [feature_of_user_two.id] },
               as: :json
      end
    end

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'No matching features found for this user.', json_response['message']
    assert Feature.exists?(feature_of_user_two.id)
  end

  test 'should return not found for non-existent feature id' do
    non_existent_id = Feature.last.id + 1
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('Feature.count') do
        delete '/user/features',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { feature_ids: [non_existent_id] },
               as: :json
      end
    end

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'No matching features found for this user.', json_response['message']
  end

  test 'should return bad request if feature_ids is missing for delete' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      delete '/user/features',
             headers: { 'Authorization' => "Bearer #{@valid_token}" },
             params: {},
             as: :json
    end

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'feature_ids parameter is required and must be an array of feature IDs.',
                 json_response['message']
  end

  test 'should return unauthorized when trying to delete without token' do
    delete '/user/features',
           params: { feature_ids: [@feature.id] },
           as: :json

    assert_response :unauthorized
  end
end
