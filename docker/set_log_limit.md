1. 在/etc/docker/daemon.json 下面添加:
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m"  // 设置日志文件的最大大小，例如10兆字节
  }
}

2.保存后，重启docker
sudo systemctl restart docker

