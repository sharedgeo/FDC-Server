# frozen_string_literal: true

require 'test_helper'

class UsersMeTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    document = fixture_file_upload('document.txt', 'text/plain')
    @user.documents.attach(document)

    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'
    @non_existent_user_token = 'non-existent-user-token'
  end

  test 'should get user with valid token' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get '/user/me', headers: { 'Authorization' => "Bearer #{@valid_token}" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal @user.id, json_response['data']['id']
    assert_equal @user.email_address, json_response['data']['email_address']

    assert_not_nil json_response['data']['documents']
    assert_kind_of Array, json_response['data']['documents']
    assert_equal 1, json_response['data']['documents'].size

    document_response = json_response['data']['documents'].first
    attached_document = @user.documents.first

    assert_not document_response.key?('id')
    assert_not document_response.key?('url')
    assert_equal attached_document.filename.to_s, document_response['filename']
    assert_equal attached_document.content_type, document_response['content_type']
    assert_equal attached_document.byte_size, document_response['byte_size']
  end

  test 'should get user with valid token and no documents' do
    user_two = users(:two)
    decoded_token = { payload: { 'email' => user_two.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get '/user/me', headers: { 'Authorization' => "Bearer #{@valid_token}" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal user_two.id, json_response['data']['id']
    assert_equal user_two.email_address, json_response['data']['email_address']
    assert_not_nil json_response['data']['documents']
    assert_equal [], json_response['data']['documents']
  end

  test 'should return not found for user that does not exist' do
    non_existent_email = 'not.found@example.com'
    decoded_token = { payload: { 'email' => non_existent_email } }
    JsonWebToken.stub :verify, decoded_token do
      get '/user/me', headers: { 'Authorization' => "Bearer #{@non_existent_user_token}" }
    end

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal "User with email '#{non_existent_email}' not found.", json_response['message']
  end

  test 'should return unauthorized for invalid token' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      get '/user/me', headers: { 'Authorization' => "Bearer #{@invalid_token}" }
    end

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'Token is invalid. Reason: Invalid token', json_response['message']
  end

  test 'should return unauthorized without token' do
    get '/user/me'

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'No token provided in Authorization header.', json_response['message']
  end

  test 'should return unprocessable entity if token payload has no email' do
    decoded_token = { payload: { 'sub' => '12345' } } # No email
    JsonWebToken.stub :verify, decoded_token do
      get '/user/me', headers: { 'Authorization' => "Bearer #{@valid_token}" }
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'Email not found in token payload.', json_response['message']
  end
end
