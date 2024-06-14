#!/bin/bash

# 최신 mariadb 다운로드
sudo cat <<EOF > /etc/yum.repos.d/MariaDB.repo
[mariadb]
name=MariaDB
#baseurl=http://yum.mariadb.org/10.6/centos74-amd64/
baseurl=https://archive.mariadb.org/yum/10.6/centos74-amd64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
enabled=1
EOF

# 레포지토리 업데이트
sudo yum check-update

# 최신 mariadb 다운로드
sudo yum -y install mariadb-server
sudo systemctl enable --now mariadb

sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.0/mysqld_exporter-0.15.0.linux-amd64.tar.gz

tar -xvf mysqld_exporter-0.15.0.linux-amd64.tar.gz

sudo mv mysqld_exporter-0.15.0.linux-amd64/mysqld_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/mysqld_exporter
mysqld_exporter --version

# mysqld_exporter 명령어가 실행되는 지 확인해야함 ( echo $PATH 에 /usr/local/bin 디렉토리 경로 있는 지 확인)
mysql -u root -e "CREATE USER 'exporter'@'%' IDENTIFIED BY '1q2w3e4r';"
mysql -u root -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'% WITH MAX_USER_CONNECTIONS 3';"
mysql -u root -e "FLUSH PRIVILEGES;"

sudo cat > .mysqld_exporter.cnf <<-EOF
[client]
host=localhost
port=3306
user=exporter
password=1q2w3e4r
EOF

sudo cp .mysqld_exporter.cnf /etc/.mysqld_exporter.cnf
sudo rm -f .mysqld_exporter.cnf

sudo chown root:prometheus /etc/.mysqld_exporter.cnf

sudo cat > mysqld_exporter.service <<-EOF
[Unit]
Description=Prometheus MySQL Exporter
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter \
--config.my-cnf /etc/.mysqld_exporter.cnf \
--collect.global_status \
--collect.info_schema.innodb_metrics \
--collect.auto_increment.columns \
--collect.info_schema.processlist \
--collect.binlog_size \
--collect.info_schema.tablestats \
--collect.global_variables \
--collect.info_schema.query_response_time \
--collect.info_schema.userstats \
--collect.info_schema.tables \
--collect.perf_schema.tablelocks \
--collect.perf_schema.file_events \
--collect.perf_schema.eventswaits \
--collect.perf_schema.indexiowaits \
--collect.perf_schema.tableiowaits \
--collect.slave_status \
--web.listen-address=0.0.0.0:9104

[Install]
WantedBy=multi-user.target
EOF

sudo cp mysqld_exporter.service /etc/systemd/system/mysqld_exporter.service
sudo systemctl daemon-reload
sudo systemctl start mysqld_exporter
sudo systemctl enable mysqld_exporter

sudo systemctl status mysqld_exporter -l

sudo rm -f mysqld_exporter-0.15.0.linux-amd64.tar.gz