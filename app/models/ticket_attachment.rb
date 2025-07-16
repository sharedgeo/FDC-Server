# frozen_string_literal: true

class TicketAttachment < ApplicationRecord
  belongs_to :user
  belongs_to :ticket
  has_many_attached :documents
end
