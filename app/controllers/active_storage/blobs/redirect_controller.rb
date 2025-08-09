# frozen_string_literal: true

# Overriding Rails default controller to add JWT authentication
#
# Take a signed permanent reference for a blob and turn it into an expiring service URL for download.
#
# WARNING: All Active Storage controllers are publicly accessible by default. The
# generated URLs are hard to guess, but permanent by design. If your files
# require a higher level of protection consider implementing
# {Authenticated Controllers}[https://guides.rubyonrails.org/active_storage_overview.html#authenticated-controllers].
class ActiveStorage::Blobs::RedirectController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob, Authenticate
  before_action :authenticate_request!

  def show
    attachment = ActiveStorage::Attachment.find_by(blob_id: @blob.id)

    unless attachment&.record&.user == current_user
      render json: { status: 'error', message: 'Document not found or unauthorized.' }, status: :not_found
      return
    end

    expires_in ActiveStorage.service_urls_expire_in
    redirect_to @blob.url(disposition: params[:disposition]), allow_other_host: true
  end
end
