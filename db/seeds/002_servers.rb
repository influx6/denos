require 'faker'

# Create some sets of servers attached to certain clusters.
clusters = Cluster.find_each.each do |cluster|
  rand(1..5).times do
    ip = Faker::Internet.unique.ip_v4_address
    Server.find_or_create_by(friendly_name: "server-#{Faker::Alphanumeric.alpha(number: 5)}", cluster_id: cluster.id, ip_string: ip) do |server|
      # nothing to see here
      puts "Created server #{server.to_json}"
    end
  end
end
