class AddSubdomainIndex < ActiveRecord::Migration[6.0]
  def change
  	add_index :clusters, :subdomain
  end
end
