#!/bin/bash
git config user.name "Travis CI"
git config user.email "travis@travis-ci.org"
helm package charts/loghouse -d charts/
git checkout gh-pages
helm repo index charts/
git add charts/
git commit -m 'add new version'
git push --set-upstream origin gh-pages
