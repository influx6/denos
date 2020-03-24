class Cluster < ApplicationRecord
  has_many :server

  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :subdomain, presence: true, uniqueness: {case_sensitive: false}, length: {maximum: 5}

  def find_servers
    return Server.where(cluster_id: self.id).order(created_at: :asc)
  end
end
