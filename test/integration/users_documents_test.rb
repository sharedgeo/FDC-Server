# frozen_string_literal: true

require 'test_helper'

class UsersDocumentsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'
    @new_user_email = 'new.user@example.com'

    file_path = Rails.root.join('test', 'fixtures', 'files', 'document.txt')
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path),
      filename: 'document.txt',
      content_type: 'text/plain'
    )
  end

  test 'should create documents for existing user' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      post '/user/documents',
           headers: { 'Authorization' => "Bearer #{@valid_token}" },
           params: { document_signed_ids: [@blob.signed_id] },
           as: :json
    end

    assert_response :success
    @user.reload
    assert @user.documents.attached?
    assert_equal 1, @user.documents.count
    assert_equal 'document.txt', @user.documents.first.filename.to_s

    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal @user.id, json_response['data']['id']
    assert_equal 1, json_response['data']['documents'].count
    assert_not_nil json_response['data']['documents'][0]['url']
  end

  test 'should create user and documents if user does not exist' do
    assert_difference('User.count', 1) do
      decoded_token = { payload: { 'email' => @new_user_email } }
      JsonWebToken.stub :verify, decoded_token do
        post '/user/documents',
             headers: { 'Authorization' => "Bearer #{@valid_token}" },
             params: { document_signed_ids: [@blob.signed_id] },
             as: :json
      end
    end

    assert_response :success
    new_user = User.find_by(email_address: @new_user_email)
    assert new_user
    assert new_user.documents.attached?
    assert_equal 1, new_user.documents.count
  end

  test 'should return bad request if document_signed_ids is missing' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      post '/user/documents',
           headers: { 'Authorization' => "Bearer #{@valid_token}" },
           params: {},
           as: :json
    end

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'document_signed_ids parameter is required and must be an array of signed IDs.',
                 json_response['message']
  end

  test 'should return unauthorized for invalid token' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      post '/user/documents',
           headers: { 'Authorization' => "Bearer #{@invalid_token}" },
           params: { document_signed_ids: [@blob.signed_id] },
           as: :json
    end

    assert_response :unauthorized
  end

  test 'should return unauthorized without token' do
    post '/user/documents',
         params: { document_signed_ids: [@blob.signed_id] },
         as: :json

    assert_response :unauthorized
  end
end
