class CreateClusters < ActiveRecord::Migration[6.0]
  def change
    create_table :clusters do |t|
      t.string :name, null: false
      t.string :subdomain, null: false

      t.timestamps
    end
  end
end
