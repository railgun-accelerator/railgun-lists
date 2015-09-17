apt-get install -y libnet-ip-perl
wget -O GeoLite2-Country-CSV.zip http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip
wget -O aggregate-cidr-addresses.pl http://www.zwitterion.org/software/aggregate-cidr-addresses/aggregate-cidr-addresses
unzip -j -o -d GeoLite2-Country-CSV GeoLite2-Country-CSV.zip
ruby regions.rb