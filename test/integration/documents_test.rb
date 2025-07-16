# test/integration/documents_test.rb

# frozen_string_literal: true

require 'test_helper'

class DocumentsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @ticket = tickets(:one) # Assuming you have a tickets fixture
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
  test 'should create ticket attachment and attach document' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('TicketAttachment.count', 1) do
        post '/v1/documents',
             headers: { 'Authorization' => "Bearer #{@valid_token}" },
             params: { ticket_id: @ticket.id, document_signed_ids: [@blob.signed_id] },
             as: :json
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'success', json_response['status']

    ticket_attachment = @user.ticket_attachments.find_by(ticket: @ticket)
    assert ticket_attachment
    assert ticket_attachment.documents.attached?
    assert_equal 1, ticket_attachment.documents.count
  end

  test 'should attach to existing ticket attachment' do
    ticket_attachment = @user.ticket_attachments.create(ticket: @ticket)

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('TicketAttachment.count') do
        post '/v1/documents',
             headers: { 'Authorization' => "Bearer #{@valid_token}" },
             params: { ticket_id: @ticket.id, document_signed_ids: [@blob.signed_id] },
             as: :json
      end
    end

    assert_response :success
    ticket_attachment.reload
    assert_equal 1, ticket_attachment.documents.count
  end

  test 'should return bad request if document_signed_ids is missing' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      post '/v1/documents',
           headers: { 'Authorization' => "Bearer #{@valid_token}" },
           params: { ticket_id: @ticket.id },
           as: :json
    end

    assert_response :bad_request
  end

  test 'should return unauthorized for invalid token when creating' do
    JsonWebToken.stub :verify, ->(_token) { raise JWT::DecodeError, 'Invalid token' } do
      post '/v1/documents',
           headers: { 'Authorization' => "Bearer #{@invalid_token}" },
           params: { ticket_id: @ticket.id, document_signed_ids: [@blob.signed_id] },
           as: :json
    end

    assert_response :unauthorized
  end

  # DELETE /v1/documents/:id
  test 'should delete a document' do
    ticket_attachment = @user.ticket_attachments.create(ticket: @ticket)
    ticket_attachment.documents.attach(@blob)

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('ActiveStorage::Attachment.count', -1) do
        delete "/v1/documents/#{@blob.signed_id}",
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               as: :json
      end
    end

    assert_response :success
  end

  test 'should not delete a document belonging to another user' do
    user_two = users(:two)
    ticket_attachment = user_two.ticket_attachments.create(ticket: @ticket)
    ticket_attachment.documents.attach(@blob)

    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_no_difference('ActiveStorage::Attachment.count') do
        delete "/v1/documents/#{@blob.signed_id}",
               headers: { 'Authorization' => "Bearer #{@valid_token}" },
               as: :json
      end
    end

    assert_response :not_found
  end
end
