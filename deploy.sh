#!/usr/bin/env bash
$(aws ecr get-login)
docker build -t giveone:latest .
docker tag giveone:latest 502734509659.dkr.ecr.us-east-1.amazonaws.com/giveone:latest
docker push 502734509659.dkr.ecr.us-east-1.amazonaws.com/giveone:latest
# sed -i'' -e "s|latest|$1|g" Dockerrun.aws.json
git add Dockerrun.aws.json
# git rm -f Dockerfile
eb init giveone --platform docker --keyname aws-eb-giveone --region us-east-1
eb use integration
eb deploy --timeout 20 --staged --label "master-$1" --message "$(git log --format=%B -n 1)"
# sed -i'' -e "s|$1|latest|g" Dockerrun.aws.json
echo "deployment complete"
