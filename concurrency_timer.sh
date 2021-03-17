#!/bin/bash
# 多账号并发，默认在零点准时触发
# 变量：要运行的脚本$SCRIPT
SCRIPT=$1
timer=${2:-00:00:00}
echo "设置时区"
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "开始多账号并发"
IFS=$'\n'
num=0
[ "$timer" = "00:00:00" ] && nextdate=`date +%s%N -d "+1 day $timer"` || nextdate=`date +%s%N -d "$timer"`
if [ -n "$JD_COOKIE" ]; then
  echo "修改cookie"
  sed -i 's/process.env.JD_COOKIE/process.env.JD_COOKIES/g' ./jdCookie.js
  JK_LIST=(`echo "$JD_COOKIE" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)
else
  JK_LIST=(`echo "$JD_COOKIES" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)
fi
num=0
for jk in ${JK_LIST[*]}
do 
  cp  -rf ~/scripts ~/scripts${num}
  cd ~/scripts${num}
  sed -i 's/let CookieJDs/let CookieJDss/g' ./jdCookie.js
  sed -i "1i\let CookieJDs = [ '$jk', ]" ./jdCookie.js
  now=`date +%s%N` && delay=`echo "scale=3;$((nextdate-now))/1000000000" | bc`
  ([ $nextdate -gt $now -a $delay -le 3600 ] && echo "未到当天${timer}，等待${delay}秒" && sleep $delay || echo "未到当天${timer}，但超出不远，继续运行"; node ./$SCRIPT) &
  cd ~
  num=$((num + 1))
done
unset IFS
wait
