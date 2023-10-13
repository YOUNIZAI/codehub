
3. docker rmi more images
docker images  |grep smf/sm |grep gcs |awk   '{print }' | xargs docker rmi 

