require 'faker'

# Create some sets of servers attached to certain clusters.
clusters = Cluster.find_each.each do |cluster|
  rand(1..5).times do
    ip = [rand(50..300), rand(20..200), rand(60..150), rand(100..400)].join(".")
    Server.find_or_create_by(friendly_name: "server-#{Faker::Alphanumeric.alpha(number: 5)}", cluster_id: cluster.id, ip_string: ip) do | server |
      # nothing to see here
      puts "Created server #{server.to_json}"
    end
  end
end
