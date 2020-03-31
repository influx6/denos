# frozen_string_literal: true
IP_ADDRESS_REGEX = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/

class Server < ApplicationRecord
  belongs_to :cluster

  validate :only_valid_ip_addresses
  validates :cluster_id, presence: true

  def only_valid_ip_addresses
    if ip_string.nil?
      errors.add(:ip_string, "can not be nil")
      return
    end
    unless ip_string.match(IP_ADDRESS_REGEX)
      errors.add(:ip_string, "can only be valid ipv4 addresses")
    end
  end
end
