#安装服务
ln -s -f $(pwd)/wireguard_keepalive.service /etc/systemd/system/

#安装程序文件
ln -s -f $(pwd)/start.sh /bin/wireguard_keepalive
