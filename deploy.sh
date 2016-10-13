sudo docker build --rm=true -t cedis .
sudo docker tag cedis  docker.io/blitline/cedis
sudo docker push  docker.io/blitline/cedis
