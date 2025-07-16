# test/integration/profiles_test.rb

require 'test_helper'

class ProfilesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @ticket = tickets(:one)
    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'

    # Create a feature associated with the user and ticket
    @feature = Feature.create!(user: @user, ticket: @ticket, geom: 'POINT (1 1)')

    # Create a ticket attachment and attach a document
    @ticket_attachment = @user.ticket_attachments.create!(ticket: @ticket)
    file_path = Rails.root.join('test', 'fixtures', 'files', 'document.txt')
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path),
      filename: 'document.txt',
      content_type: 'text/plain'
    )
    @ticket_attachment.documents.attach(@blob)
  end

  test 'should show profile with tickets, features, and documents' do
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

    # Check tickets
    assert_equal 1, data['tickets'].count
    ticket_data = data['tickets'][0]
    assert_equal @ticket.id, ticket_data['id']

    # Check features within the ticket
    assert_equal 1, ticket_data['features'].count
    feature_data = ticket_data['features'][0]
    assert_equal @feature.id, feature_data['id']
    assert_equal @feature.geom, feature_data['geom']

    # Check documents within the ticket
    assert_equal 1, ticket_data['documents'].count
    document_data = ticket_data['documents'][0]
    assert_equal @blob.signed_id, document_data['signed_id']
    assert_equal 'document.txt', document_data['filename']
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

  test 'should create user and show empty profile if user does not exist' do
    new_user_email = 'new.user@example.com'
    decoded_token = { payload: { 'email' => new_user_email } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference 'User.count', 1 do
        get '/v1/profile', headers: { 'Authorization' => "Bearer #{@valid_token}" }, as: :json
      end
    end
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']
    data = json_response['data']
    assert_equal new_user_email, data['email_address']
    assert_equal [], data['tickets']
  end
end
