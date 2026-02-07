#!/usr/bin/env bash
set -e

kubectl -n task5 run front-end-app \
  --image=nginx \
  --labels role=front-end \
  --expose --port 80

kubectl -n task5 run back-end-api-app \
  --image=nginx \
  --labels role=back-end-api \
  --expose --port 80

kubectl -n task5 run admin-front-end-app \
  --image=nginx \
  --labels role=admin-front-end \
  --expose --port 80

kubectl -n task5 run admin-back-end-api-app \
  --image=nginx \
  --labels role=admin-back-end-api \
  --expose --port 80

echo "Pods:"
kubectl -n task5 get pods
echo
echo "Services:"
kubectl -n task5 get svc

