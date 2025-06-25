# frozen_string_literal: true

class Feature < ApplicationRecord
  belongs_to :user

  validates :geom, presence: true
end
