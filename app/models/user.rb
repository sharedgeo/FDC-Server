# frozen_string_literal: true

class User < ApplicationRecord
  has_many_attached :documents
  has_many :features
end
