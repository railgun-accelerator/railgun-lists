require 'csv'
require 'pg'
require 'ipaddr'

$geonames = {}
$routes = Hash.new { |hash, key| hash[key] = [] }

puts 'loading GeoLite2'

CSV.foreach('GeoLite2-Country-CSV/GeoLite2-Country-Locations-en.csv', headers: true) do |row|
  case
    when row['country_iso_code']== 'CN'
      $geonames[row['geoname_id']] = 2 # CN
    when ['AS', 'OC'].include?(row['continent_code'])
      $geonames[row['geoname_id']] = 1 # AP
  end
end

$routes[0] = ['0.0.0.0/0']
CSV.foreach('GeoLite2-Country-CSV/GeoLite2-Country-Blocks-IPv4.csv', headers: true) do |row|
  if (region = $geonames[row['geoname_id']])
    $routes[region].push row['network']
  end
end

puts 'combine CIDR'

# 合并路由表以减少数量
$routes.each_pair do |region_id, addresses|
  result = addresses.map{|address|IPAddr.new(address).to_range}.sort_by{|range|range.min}
  p result[0].max, result[0].min
end

puts 'save to database'

conn = PG.connect( ENV['railgun_database'] )
conn.prepare 'insert_address', "INSERT INTO addresses (address, region_id) VALUES ($1, $2)"
conn.transaction do |conn|
  conn.exec 'truncate table addresses'
  $routes.each_pair do |region_id, addresses|
    NetAddr.merge(addresses.map{|address|NetAddr::CIDR.create(address)}).each do |address|
      puts "#{region_id}:#{address}"
      conn.exec_prepared 'insert_address', [address, region_id]
    end
  end
end