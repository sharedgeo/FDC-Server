# test/integration/documents_test.rb

# frozen_string_literal: true

require 'test_helper'

class DocumentsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'

    file_path = Rails.root.join('test', 'fixtures', 'files', 'document.txt')
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path),
      filename: 'document.txt',
      content_type: 'text/plain'
    )
  end

  # POST /v1/documents
  test 'should create documents for existing user' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      post '/v1/documents',
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
    assert_equal 'Document(s) attached successfully.', json_response['message']
  end

  test 'should return unauthorized if user does not exist' do
    new_user_email = 'new.user@example.com'
    assert_no_difference('User.count') do
      decoded_token = { payload: { 'email' => new_user_email } }
      JsonWebToken.stub :verify, decoded_token do
        post '/v1/documents',
             headers: { 'Authorization' => "Bearer #{@valid_token}" },
             params: { document_signed_ids: [@blob.signed_id] },
             as: :json
      end
    end

    assert_response :unauthorized
  end

  test 'should return bad request if document_signed_ids is missing' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      post '/v1/documents',
           headers: { 'Authorization' => "Bearer #{@valid_token}" },
           params: {},
           as: :json
    end

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'document_signed_ids parameter is required.', json_response['message']
  end

  test 'should return unauthorized for invalid token when creating' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      post '/v1/documents',
           headers: { 'Authorization' => "Bearer #{@invalid_token}" },
           params: { document_signed_ids: [@blob.signed_id] },
           as: :json
    end

    assert_response :unauthorized
  end

  test 'should return unauthorized without token when creating' do
    post '/v1/documents',
         params: { document_signed_ids: [@blob.signed_id] },
         as: :json

    assert_response :unauthorized
  end

  # DELETE /v1/documents/:id
  test 'should delete a document for an existing user' do
    @user.documents.attach(@blob)
    assert_equal 1, @user.documents.count

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('ActiveStorage::Attachment.count', -1) do
        delete "/v1/documents/#{@blob.signed_id}",
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               as: :json
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal 'Document deleted successfully.', json_response['message']

    @user.reload
    assert_not @user.documents.attached?
  end

  test 'should not delete a document belonging to another user' do
    user_two = users(:two)
    user_two.documents.attach(@blob)
    assert user_two.documents.attached?

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('ActiveStorage::Attachment.count') do
        delete "/v1/documents/#{@blob.signed_id}",
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               as: :json
      end
    end

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'Document not found for this user.', json_response['message']

    user_two.reload
    assert user_two.documents.attached?
  end

  test 'should return unprocessable entity for malformed signed id' do
    @user.documents.attach(@blob)

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('ActiveStorage::Attachment.count') do
        delete '/v1/documents/this-is-not-a-signed-id',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               as: :json
      end
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'Invalid signed ID.', json_response['message']
  end

  test 'should return unauthorized when trying to delete without token' do
    @user.documents.attach(@blob)
    delete "/v1/documents/#{@blob.signed_id}",
           as: :json

    assert_response :unauthorized
  end
end
