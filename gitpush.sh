#!/bin/bash

cd /config/

git add .
git status
git commit -m "automatic upload by server"
git push -f origin master

exit
