

2. 删除 docker volume(volume 太多 会消耗多余 空间)
(link:) [https://johng.cn/docker-disk-usage-analyse-and-clean/#i] 
-  docker system df 
-  docker volume rm $(docker volume ls -qf dangling=true)

