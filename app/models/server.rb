# frozen_string_literal: true

class Server < ApplicationRecord
  belongs_to :cluster

  validate :only_valid_ip_addresses
  validates :cluster_id, presence: true

  def only_valid_ip_addresses
    if ip_string.nil?
      errors.add(:ip_string, "can not be nil")
      return
    end
    unless ip_string.match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/)
      errors.add(:ip_string, "can only be valid ipv4 addresses")
    end
    if Server.where(ip_string: ip_string).exists?
      errors.add(:ip_string, "duplicate ip_string not allowed")
    end
  end
end
