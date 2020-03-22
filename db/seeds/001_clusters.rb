[
    ['Los Angels', 'la'],
    ['New York', 'ny'],
    ['FrankFurt', 'frk'],
    ['Hong Kong', 'hk'],
    ['Berlin', 'br'],
    ['Lagos', 'lg'],
    ['Macau', 'ma'],
    ['Ogun', 'og'],
    ['Akra', 'ak'],
].each do |item|
  Cluster.find_or_create_by(name: item[0], subdomain: item[1])  do |cluster|
    # do nothing for now
    puts "Created cluster #{cluster.to_json}"
  end
end

