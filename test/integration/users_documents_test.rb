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
    assert_not_nil json_response['data']['documents'][0]['signed_id']
    # assert_not_nil json_response['data']['documents'][0]['url']
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

  # Tests for DELETE /user/documents
  test 'should delete a single document for an existing user' do
    @user.documents.attach(@blob)
    assert_equal 1, @user.documents.count

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('ActiveStorage::Attachment.count', -1) do
        delete '/user/documents',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { document_signed_ids: [@blob.signed_id] },
               as: :json
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '1 document(s) deleted successfully.', json_response['message']

    @user.reload
    assert_not @user.documents.attached?
  end

  test 'should delete multiple documents for an existing user' do
    file_path2 = Rails.root.join('test', 'fixtures', 'files', 'document.txt')
    blob2 = ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path2),
      filename: 'document2.txt',
      content_type: 'text/plain'
    )
    @user.documents.attach(@blob)
    @user.documents.attach(blob2)
    assert_equal 2, @user.documents.count

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('ActiveStorage::Attachment.count', -2) do
        delete '/user/documents',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { document_signed_ids: [@blob.signed_id, blob2.signed_id] },
               as: :json
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    assert_equal '2 document(s) deleted successfully.', json_response['message']

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
        delete '/user/documents',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { document_signed_ids: [@blob.signed_id] },
               as: :json
      end
    end

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'No matching documents found for this user.', json_response['message']

    user_two.reload
    assert user_two.documents.attached?
  end

  test 'should return not found for a valid but non-existent signed id' do
    # Create a blob, get its signed ID, then destroy it to simulate a non-existent blob.
    file_path = Rails.root.join('test', 'fixtures', 'files', 'document.txt')
    temp_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path),
      filename: 'temp_document.txt',
      content_type: 'text/plain'
    )
    non_existent_signed_id = temp_blob.signed_id
    temp_blob.purge

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('ActiveStorage::Attachment.count') do
        delete '/user/documents',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { document_signed_ids: [non_existent_signed_id] },
               as: :json
      end
    end

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'One or more documents were not found.', json_response['message']
  end

  test 'should return unprocessable entity for malformed signed id' do
    @user.documents.attach(@blob)

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('ActiveStorage::Attachment.count') do
        delete '/user/documents',
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               params: { document_signed_ids: ['this is not a signed id'] },
               as: :json
      end
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['status']
    assert_equal 'One or more signed IDs are invalid.', json_response['message']
  end

  test 'should return bad request if document_signed_ids is missing for delete' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      delete '/user/documents',
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

  test 'should return unauthorized when trying to delete without token' do
    @user.documents.attach(@blob)
    delete '/user/documents',
           params: { document_signed_ids: [@blob.signed_id] },
           as: :json

    assert_response :unauthorized
  end
end
