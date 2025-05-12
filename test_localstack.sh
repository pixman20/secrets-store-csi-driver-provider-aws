#!/bin/bash

set -e

if [ -z "$1" ]; then
    read -p "Please enter the cluster container name: " cluster_container_name
else
    cluster_container_name=$1
fi

export PRIVREPO=localhost/aws-secrets-manager/secrets-store-csi-driver-provider-aws
export TAG=latest-arm64
export PLATFORM=linux/arm64
export NAMESPACE=bitwarden
make build
make docker-buildx
docker save $PRIVREPO:$TAG --platform=$PLATFORM > image.tar
docker cp image.tar $cluster_container_name:/tmp/image.tar
docker exec -it $cluster_container_name sh -c "ctr images rm $PRIVREPO:$TAG || true"
docker exec -it $cluster_container_name sh -c "ctr images import /tmp/image.tar"
docker exec -it $cluster_container_name sh -c "ctr images list | grep $PRIVREPO"


helm uninstall aws-secrets-manager || true
helm upgrade --install aws-secrets-manager charts/secrets-store-csi-driver-provider-aws --namespace $NAMESPACE --set awsEndpointUrl=http://localhost.localstack.cloud:4566 --set image.repository=$PRIVREPO --set image.tag=$TAG
