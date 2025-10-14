# frozen_string_literal: true

require 'test_helper'

class BookmarksTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @ticket = tickets(:one)
    @bookmark = bookmarks(:one)
  end

  def auth_headers(token = 'dummy_token')
    { 'Authorization' => "Bearer #{token}" }
  end

  # Create tests
  test 'should create bookmark with valid token' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('Bookmark.count') do
        post '/v1/bookmarks', params: { ticket_id: @ticket.id }, headers: auth_headers, as: :json
      end
    end
    assert_response :created
  end

  test 'should not create bookmark without ticket_id' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      post '/v1/bookmarks', params: {}, headers: auth_headers, as: :json
    end
    assert_response :unprocessable_entity
  end

  test 'should not create bookmark without auth token' do
    post '/v1/bookmarks', params: { ticket_id: @ticket.id }, as: :json
    assert_response :unauthorized
  end

  # Destroy tests
  test 'should destroy bookmark with valid token' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      assert_difference('Bookmark.count', -1) do
        delete "/v1/bookmarks/#{@bookmark.id}", headers: auth_headers, as: :json
      end
    end
    assert_response :ok
  end

  test 'should not destroy bookmark of another user' do
    other_user = users(:two)
    decoded_token = { payload: { 'email' => other_user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      delete "/v1/bookmarks/#{@bookmark.id}", headers: auth_headers, as: :json
    end
    assert_response :not_found
  end

  test 'should not destroy non-existent bookmark' do
    decoded_token = { payload: { 'email' => @user.email_address } }
    JsonWebToken.stub :verify, decoded_token do
      delete '/v1/bookmarks/9999', headers: auth_headers, as: :json
    end
    assert_response :not_found
  end

  test 'should not destroy bookmark without auth token' do
    delete "/v1/bookmarks/#{@bookmark.id}", as: :json
    assert_response :unauthorized
  end
end
