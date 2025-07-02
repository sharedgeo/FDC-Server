# test/integration/profiles_test.rb

require 'test_helper'

class ProfilesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'

    # Attach a document
    file_path = Rails.root.join('test', 'fixtures', 'files', 'document.txt')
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path),
      filename: 'document.txt',
      content_type: 'text/plain'
    )
    @user.documents.attach(@blob)

    # Create a feature
    @feature = Feature.create!(user: @user, geom: 'POINT (1 1)')
  end

  test 'should show profile for authenticated user' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get '/v1/profile', headers: { 'Authorization' => "Bearer #{@valid_token}" }, as: :json
    end

    assert_response :ok

    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']

    data = json_response['data']
    assert_equal @user.id, data['id']
    assert_equal @user.email_address, data['email_address']

    # Check features
    assert_equal 1, data['features'].count
    assert_equal @feature.id, data['features'][0]['id']
    assert_equal @feature.geom, data['features'][0]['geom']

    # Check documents
    assert_equal 1, data['documents'].count
    document_data = data['documents'][0]
    assert_equal @blob.signed_id, document_data['signed_id']
    assert_equal 'document.txt', document_data['filename']
    assert document_data['url'].present?
    assert_equal @blob.content_type, document_data['content_type']
    assert_equal @blob.byte_size, document_data['byte_size']
  end

  test 'should return unauthorized without token' do
    get '/v1/profile', as: :json
    assert_response :unauthorized
  end

  test 'should return unauthorized with invalid token' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      get '/v1/profile', headers: { 'Authorization' => "Bearer #{@invalid_token}" }, as: :json
    end
    assert_response :unauthorized
  end

  test 'should return unauthorized if user does not exist' do
    new_user_email = 'new.user@example.com'
    decoded_token = { payload: { 'email' => new_user_email } }
    JsonWebToken.stub :verify, decoded_token do
      get '/v1/profile', headers: { 'Authorization' => "Bearer #{@valid_token}" }, as: :json
    end
    assert_response :unauthorized
  end
end
