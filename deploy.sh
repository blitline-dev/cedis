docker build --rm=true -t cedis .
docker tag cedis  docker.io/blitline/cedis
docker push  docker.io/blitline/cedis
