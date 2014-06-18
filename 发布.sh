#!/bin/sh
rake generate
git add .
git commit -am "new post"
git push origin source
rake deploy