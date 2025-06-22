# frozen_string_literal: true

class Ticket < ApplicationRecord
  has_many_attached :documents
end
