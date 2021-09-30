docker build -t gcr.io/$PROJECT_ID/chrome:`date +%d%m%Y` -t gcr.io/$PROJECT_ID/chrome:latest .
docker push gcr.io/$PROJECT_ID/chrome:`date +%d%m%Y`
docker push gcr.io/$PROJECT_ID/chrome:latest
