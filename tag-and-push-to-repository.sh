#!/bin/bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ -f $BASE_DIR/config ] ; then
	. $BASE_DIR/config
else
	echo "Missing configuration"
	exit 1
fi

DOCKER_IMAGES="jpetstore-usa-account-service jpetstore-order-service jpetstore-frontend-service jpetstore-catalog-service jpetstore-account-service"

for I in $DOCKER_IMAGES ; do
	docker tag $I $DOCKER_REPO/$I
	docker push $DOCKER_REPO/$I
done

# end
