# test/integration/blobs_redirect_test.rb

require 'test_helper'

class BlobsRedirectTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @ticket = tickets(:one)
    @valid_token = 'valid-token'
    @invalid_token = 'invalid-token'

    file_path = Rails.root.join('test', 'fixtures', 'files', 'document.txt')
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path),
      filename: 'document.txt',
      content_type: 'text/plain'
    )

    # The controller expects the blob to be attached to a record that has a user.
    # In our app, that's a TicketAttachment.
    ticket_attachment = @user.ticket_attachments.create(ticket: @ticket)
    ticket_attachment.documents.attach(@blob)
  end

  test 'should redirect to blob url for authenticated user' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get url_for(@blob),
          headers: { 'Authorization' => "Bearer #{@valid_token}" }
    end
    assert_response :redirect
  end

  test 'should return unauthorized for request without token' do
    get url_for(@blob)
    assert_response :unauthorized
  end

  test 'should return unauthorized for request with invalid token' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      get url_for(@blob),
          headers: { 'Authorization' => "Bearer #{@invalid_token}" }
    end
    assert_response :unauthorized
  end

  test 'should return not found for file belonging to another user' do
    user_two = users(:two)
    decoded_token = { payload: { 'email' => user_two.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      get url_for(@blob),
          headers: { 'Authorization' => "Bearer #{@valid_token}" }
    end
    assert_response :not_found
  end
end
