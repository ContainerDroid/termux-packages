#! /bin/bash

GITHUB_REPO=prebuilts

# set the base dir for all the work
cd "$TRAVIS_BUILD_DIR"

# setup user to push to github
git config --global user.email "travis@travis-ci.org"
git config --global user.name "Travis CI"

# clone the prebuilts repo
git clone https://github.com/LineageOSPlus/$GITHUB_REPO.git $GITHUB_REPO
cd $GITHUB_REPO; git log --oneline; cd ..

# overlay the new debs over the ones already on the prebuilts repo
wget https://raw.githubusercontent.com/LineageOSPlus/termux-apt-repo/master/termux-apt-repo
chmod +x termux-apt-repo
./termux-apt-repo debs $GITHUB_REPO

# push everything to github
cd $GITHUB_REPO
pip install mako
python make_index.py dists/
git add .
git commit --message "updated debs for commit $TRAVIS_COMMIT"
git log --oneline
git remote add prebuilts https://${GITHUB_TOKEN}@github.com/LineageOSPlus/$GITHUB_REPO.git
git push prebuilts master

# revert to the build dir
cd "$TRAVIS_BUILD_DIR"

