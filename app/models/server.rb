IP_ADDRESS_REGEX = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/

class Server < ApplicationRecord
  belongs_to :cluster

  validates :cluster_id, presence: true
  validates :ip_string, presence: true, uniqueness: true
  validate :only_valid_ip_addresses

  def get_cluster
    return Cluster.find_by(id: self.cluster_id)
  end

  def only_valid_ip_addresses
    if self.ip_string == nil
      errors.add(:ip_string, "can not be nil")
      return
    end
    if self.ip_string != nil && !self.ip_string.match(IP_ADDRESS_REGEX)
      errors.add(:ip_string, "can only be valid ipv4 addresses")
    end
  end
end
