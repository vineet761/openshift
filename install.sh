#!/bin/sh
echo "Deploying Elastic Stack..."

# Install JRE
apt-get update && apt-get install openjdk-8-jre-headless -y

# Install ELK
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch -y

# Configure and start ElasticSearch
cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.bak
sed -i "s/#network.host: 192.168.0.1/network.host: 0.0.0.0/g" /etc/elasticsearch/elasticsearch.yml
sed -i "s/#http.port:/http.port:/g" /etc/elasticsearch/elasticsearch.yml
systemctl start elasticsearch
systemctl enable elasticsearch

# Configure and start Kibana
cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.bak
sed -i "s/#server.port:/server.port:/g" /etc/kibana/kibana.yml
sed -i "s/#server.host: \"localhost\"/server.host: \"0.0.0.0\"/g" /etc/kibana/kibana.yml
sed -i "s/#elasticsearch.hosts:/elasticsearch.hosts:/g" /etc/kibana/kibana.yml
systemctl start kibana
systemctl enable kibana

# Configure and start Logstash
cat <<EOF > /etc/logstash/conf.d/was_logstash.conf
input {
    beats {
        port => "5044"
        ssl => false
    }
}
filter {
    json {
        source => "message"
    }
}
output {
    elasticsearch {
        hosts => "localhost:9200"
    }
}
EOF
systemctl start logstash
systemctl enable logstash

echo "Deploy Elastic Stack completed"
