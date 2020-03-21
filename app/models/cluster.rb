class Cluster < ApplicationRecord
  validates_presence_of :name
  validates_presence_of :subdomain

end
