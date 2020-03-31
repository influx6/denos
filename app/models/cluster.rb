# frozen_string_literal: true
class Cluster < ApplicationRecord
  has_many :server

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :subdomain, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 5 }
end
