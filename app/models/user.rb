# frozen_string_literal: true

class User < ApplicationRecord
  has_many :ticket_attachments
  has_many :bookmarks
  has_many :features
  has_many :tickets_from_attachments, through: :ticket_attachments, source: :ticket
  has_many :tickets_from_bookmarks, through: :bookmarks, source: :ticket
  has_many :tickets_from_features, through: :features, source: :ticket

  def all_tickets
    (tickets_from_bookmarks.each { |t| t.decorate(self) } +
     tickets_from_attachments +
     tickets_from_features).uniq.sort_by(&:ticket_no)
  end
end
