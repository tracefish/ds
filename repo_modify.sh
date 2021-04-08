#!/usr/bin/env sh

set -e

mkdir -p ~/jd_scripts/
git clone https://github.com/tracefish/ds ~/jd_scripts
git config --global user.email "tracefish@qq.com"
git config --global user.name "tracefish"
cd ~/jd_scripts/.github/workflows
for f in `ls ./`
do 
  cat $f | grep -i "JD_COOKIES" && sed -i 's/JD_COOKIES/JD_COOKIE/g' $f
done
for f in `ls ./`
do 
  cat $f | grep -vi "DD_BOT_TOKEN_SPEC" && sed -i 's/          DD_BOT_SECRET: ${{ secrets.DD_BOT_SECRET }}/          DD_BOT_SECRET: ${{ secrets.DD_BOT_SECRET }}\n          DD_BOT_TOKEN_SPEC: ${{ secrets.DD_BOT_TOKEN_SPEC }}\n          DD_BOT_SECRET_SPEC: ${{ secrets.DD_BOT_SECRET_SPEC }}/g' $f
done

cd ~/jd_scripts
git add .
git commit -m "update `date +%Y%m%d%H%M%S`"

#UPSTREAM_REPO=`git remote -v | grep origin | grep fetch | awk '{print $2}'`
git remote --verbose

echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
sudo git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
git remote --verbose

echo "Pushing changings from tmp_upstream to origin"
sudo git push origin "$REPO_BRANCH:$REPO_BRANCH" --force

git remote --verbose
