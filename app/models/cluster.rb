class Cluster < ApplicationRecord
  has_many :server
  
  validates :name, presence: true
  validates :subdomain, presence: true, length: { maximum: 5 }

  def find_servers
    return Server.where(cluster_id: self.id).order(created_at: :asc)
  end
end
