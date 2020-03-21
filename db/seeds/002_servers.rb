require 'faker'

clusters = Cluster.find_each.each do |cluster|
  rand(1..10).times do
    ip = [rand(50..300), rand(20..200), rand(60..150), rand(100..400)].join(".")
    Server.find_or_create_by(friendly_name: Faker::Name.unique.first_name, cluster_id: cluster.id, ip_string: ip) do | server |
      # nothing to see here
      puts "Created server #{server.to_json}"
    end
  end
end