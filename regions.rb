require 'csv'
require 'pg'

$geonames = {}
$routes = {}

CSV.foreach('GeoLite2-Country-CSV/GeoLite2-Country-Locations-en.csv', headers: true) do |row|
  case
    when row['country_iso_code']== 'CN'
      $geonames[row['geoname_id']] = 2 # CN
    when ['AS', 'OC'].include?(row['continent_code'])
      $geonames[row['geoname_id']] = 1 # AP
  end
end

CSV.foreach('GeoLite2-Country-CSV/GeoLite2-Country-Blocks-IPv4.csv', headers: true) do |row|
  if region = $geonames[row['geoname_id']]
    $routes[row['network']] = region
  end
end

#TODO: 合并路由表以减少数量

conn = PG.connect( ENV['railgun_database'] )
conn.prepare 'insert_address', "INSERT INTO addresses (address, region_id) VALUES ($1, $2)"
conn.transaction do |conn|
  conn.exec 'truncate table addresses'
  conn.exec_prepared 'insert_address', ['0.0.0.0/0', 0]
  $routes.each do |address, region_id|
    conn.exec_prepared 'insert_address', [address, region_id]
  end
end