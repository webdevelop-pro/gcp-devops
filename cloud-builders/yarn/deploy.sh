docker build -t gcr.io/unfederalreserve-dev/yarn:`date +%d%m%Y` .
docker push gcr.io/unfederalreserve-dev/yarn:`date +%d%m%Y`

docker build -t gcr.io/unfederalreserve-dev/yarn:latest .
docker push gcr.io/unfederalreserve-dev/yarn:latest
