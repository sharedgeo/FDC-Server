# frozen_string_literal: true

class BookmarksController < ApplicationController
  before_action :authenticate_request!

  def create
    begin
      bookmark = current_user.bookmarks.create!(bookmark_params)
      render json: { status: 'success', message: 'Bookmark created successfully.', bookmark_id: bookmark.id },
             status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { status: 'error', message: e.message }, status: :unprocessable_entity
    rescue ActionController::ParameterMissing => e
      render json: { status: 'error', message: e.message }, status: :bad_request
    end
  end

  def destroy
    bookmark = current_user.bookmarks.find_by(id: params[:id])

    if bookmark
      bookmark.destroy
      render json: { status: 'success', message: 'Bookmark deleted successfully.' }, status: :ok
    else
      render json: { status: 'error', message: 'Bookmark not found.' }, status: :not_found
    end
  end

  private

  def bookmark_params
    params.permit(:ticket_id)
  end
end
