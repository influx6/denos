class AddIpStringIndex < ActiveRecord::Migration[6.0]
  def change
  	add_index :servers, :ip_string
  end
end
