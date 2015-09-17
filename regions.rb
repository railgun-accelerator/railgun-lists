require 'csv'
require 'pg'
require 'open3'

$geonames = {}
$routes = Hash.new { |hash, key| hash[key] = [] }

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

#TODO: 合并路由表以减少数量

conn = PG.connect( ENV['railgun_database'] )
conn.prepare 'insert_address', "INSERT INTO addresses (address, region_id) VALUES ($1, $2)"
conn.transaction do |conn|
  conn.exec 'truncate table addresses'
  $routes.each_pair do |region_id, addresses|
    stdout, stderr, status = Open3.capture3 "perl aggregate-cidr-addresses.pl", stdin_data: addresses.join("\n")
    stdout.lines.each do |line|
      address = line.chomp
      conn.exec_prepared 'insert_address', [address, region_id]
    end
  end
end