wget -O GeoLite2-Country-CSV.zip http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip
unzip -j -o -d GeoLite2-Country-CSV GeoLite2-Country-CSV.zip
ruby regions.rb