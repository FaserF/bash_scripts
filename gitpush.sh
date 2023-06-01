#!/bin/bash

cd /config/

git pull origin master
git add .
git status
git commit -m "automatic upload by server"
git push -f origin master

exit
