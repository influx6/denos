class CreateServers < ActiveRecord::Migration[6.0]
  def change
    create_table :servers do |t|
      t.string :ip_string
      t.string :friendly_name
      t.bigint :cluster_id

      t.timestamps
    end
  end
end
