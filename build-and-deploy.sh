#!/bin/bash
EB_ENV=$1

function green_echo {
  GREEN='\033[0;32m'
  NC='\033[0m' # no color
  DOUBLE_SPACE='  '
  echo -e "\n\n${GREEN}🤖${DOUBLE_SPACE}${1}${NC}"
}

function build_docker_image {
  green_echo "Building final docker image from source image base-$EB_ENV for EB env $EB_ENV"
  docker build -q -t giveone:latest .
}

function push_docker_image_to_ecr {
  green_echo "Pushing final docker image to ECR with tag $CIRCLE_SHA1"
  # we tag the image with the SHA1 of the commit for ECR (circle provides us with this via $CIRCLE_SHA1)
  docker tag giveone:latest $DOCKER_URL/giveone:$CIRCLE_SHA1 && \
  docker push $DOCKER_URL/giveone:$CIRCLE_SHA1
}

function deploy_docker_image_to_elastic_beanstalk_environment {
  green_echo "Preparing deployment of giveone:$CIRCLE_SHA1 to EB env $EB_ENV"
  sed -i'' -e "s|latest|$CIRCLE_SHA1|g" Dockerrun.aws.json && \
  git add Dockerrun.aws.json && \
  git rm -f Dockerfile && \
  eb init giveone --platform docker --keyname aws-eb-giveone --region us-east-1 && \
  eb use $EB_ENV && \
  green_echo "Beginning deployment of tag $CIRCLE_SHA1 to EB env $EB_ENV"
  eb deploy --timeout 20 --staged --label "$EB_ENV-$CIRCLE_SHA1" --message "$(git log --format=%B -n 1)" && \
  green_echo "Deployment of giveone:$CIRCLE_SHA1 to EB env $EB_ENV completed successfully!"
}

# deployment process begins here
green_echo "Beginning deployment of branch $CIRCLE_BRANCH to EB env $EB_ENV" && \
build_docker_image && \
push_docker_image_to_ecr && \
deploy_docker_image_to_elastic_beanstalk_environment && \
exit 0
