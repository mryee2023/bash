#!/bin/bash

# 默认版本号（如果未指定则使用该默认值）
version="v2.6.0"

# 解析命令行参数
while getopts "v:" opt; do
  case $opt in
    v) version="$OPTARG" ;;
    *) echo "Usage: $0 -v <version>"; exit 1 ;;
  esac
done

# 获取当前工作目录
dir=$(pwd)

# 下载并解压
wget -O /tmp/realm.tar.gz https://github.com/zhboner/realm/releases/download/$version/realm-x86_64-unknown-linux-gnu.tar.gz
tar -xvf /tmp/realm.tar.gz -C /tmp
chmod +x /tmp/realm
mkdir -p ./realm
mv /tmp/realm ./realm/realm

# 创建配置文件
cat <<EOF > ./realm/config.toml
[[endpoints]]
listen = "0.0.0.0:5000"
remote = "8.8.8.8:443"

[[endpoints]]
listen = "0.0.0.0:6000"
remote = "[2400:3200::1]:443"
EOF

# 创建 systemd 服务文件
cat <<EOF | sudo tee /etc/systemd/system/realm.service > /dev/null
[Unit]
Description=realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
DynamicUser=true
WorkingDirectory=$dir/realm
ExecStart=$dir/realm/realm -c $dir/realm/config.toml

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd，并启动服务
sudo systemctl daemon-reload
sudo systemctl enable realm
sudo systemctl start realm
sudo systemctl status realm
