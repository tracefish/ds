#!/usr/bin/env sh
echo "设置时区"
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

git branch -r
ls
echo "修改源码"
sed -i "s/indexOf('GITHUB')/indexOf('GOGOGOGO')/g" `ls -l |grep -v ^d|awk '{print $9}'`
sed -i 's/indexOf("GITHUB")/indexOf("GOGOGOGO")/g' `ls -l |grep -v ^d|awk '{print $9}'`
npm install

echo "拉取源码"
#git clone --depth 1 -b jd https://github.com/tracefish/ds.git ~/scripts
mkdir ~/scripts
cp -rf ./*  ~/scripts

cd ..
[ -e "run_scripts.sh" ] && chmod 755 run_scripts.sh