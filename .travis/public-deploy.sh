#!/bin/bash

setup_ssh() {
    eval "$(ssh-agent -s)"
    chmod 600 .travis/deploy.key
    ssh-add .travis/deploy.key
    ssh-keyscan ${REMOTE_HOST} >> $HOME/.ssh/known_hosts
    ssh-keyscan ${REMOTE_HOST_IP} >> $HOME/.ssh/known_hosts
}
setup_git() {
  git config user.email "travis@travis-ci.org"
  git config user.name "Travis CI"
  mkdir deploy
  cd deploy
  git init
  git remote add deploy "${REMOTE_HOST_GIT_URL}" > /dev/null 2>&1
  git config push.default simple
  git remote -v
  git fetch deploy master
  git pull deploy master
  cd ..
}

commit_files() {
  mkdir deploy/dist
  mkdir deploy/scripts
  mkdir deploy/client
  rm -rf ./dist/node_modules
  rm -rf ./dist/core/node_modules
  rm -rf ./dist/auth/node_modules
  cp -av ./scripts/* ./deploy/scripts
  cp -av ./dist/* ./deploy/dist
  cp -av ./client/* ./deploy/client
  cp -av ./package.json ./deploy/package.json 
  cp -av ./.gitignore ./deploy/.gitignore
  cp -av ./ormconfig.js ./deploy/ormconfig.js
  cp -av ./angular.json ./deploy/angular.json
  cp -av ./tsconfig.json ./deploy/tsconfig.json
  cp -av ./README.md ./deploy/README.md  
  cd deploy
  git add .
  git commit --message "Version: $PACKAGE_VERSION Commit: $TRAVIS_COMMIT"
  git push --quiet --set-upstream deploy master
  cd ..
}

upload_files() {
  rm -rf .git
  cd deploy
  git push deploy master
  cd ..
}

if [[ $TRAVIS_BRANCH == 'master' ]]
then
  PACKAGE_VERSION=$(cat package.json \
    | grep version \
    | head -1 \
    | awk -F: '{ print $2 }' \
    | sed 's/[",]//g')
  export PACKAGE_VERSION=$PACKAGE_VERSION

  setup_ssh
  setup_git
  commit_files
  upload_files
fi
