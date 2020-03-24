class CreateServers < ActiveRecord::Migration[6.0]
  def change
    create_table :servers do |t|
      t.string :ip_string, unique: true, null: false
      t.string :friendly_name
      t.bigint :cluster_id

      t.timestamps
    end
  end
end
