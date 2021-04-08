#!/bin/bash
# 多账号并发，默认在零点准时触发
# 变量：要运行的脚本$SCRIPT
# $2 小于等于十分钟，需要设置定时在上一个小时触发
SCRIPT=$1
min=${2}
echo "设置时区"
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hour=`date +%H`
if [ $min -le 10 ]; then
  hour=$((hour + 1))
  [ "$hour" = "24" ] && hour="00"
fi
timer="${hour}:${min}:00"
echo "当前时间: `date`"
echo "开始多账号并发"
IFS=$'\n'
num=0
[ "$timer" = "00:00:00" ] && nextdate=`date +%s%N -d "+1 day $timer"` || nextdate=`date +%s%N -d "$timer"`

cd ~/scripts

if [ -n "$SYNCURL" ]; then
    echo "下载脚本"
    curl "$SYNCURL" > "./$1"
    # 外链脚本替换
    sed -i "s/indexOf('GITHUB')/indexOf('GOGOGOGO')/g" `ls -l |grep -v ^d|awk '{print $9}'`
    sed -i 's/indexOf("GITHUB")/indexOf("GOGOGOGO")/g' `ls -l |grep -v ^d|awk '{print $9}'`
fi
[ ! -e "./$1" ] && echo "脚本不存在" && exit 0

echo "DECODE"
encode_str=(`cat ./$1 | grep "window" | awk -F "window" '{print($1)}'| awk -F "var " '{print $(NF-1)}' | awk -F "=" '{print $1}' | sort -u`)
if [ -n "$encode_str" ]; then
    for ec in ${encode_str[*]}
    do
        sed -i "s/return $ec/if($ec.toLowerCase()==\"github\"){$ec=\"GOGOGOGO\"};return $ec/g" ./$1
    done
fi

echo "修改cookie"
sed -i 's/process.env.JD_COOKIE/process.env.JD_COOKIES/g' ./jdCookie.js
JK_LIST=(`echo "$JD_COOKIE" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)

echo "修改发送方式"
cp -f ./sendNotify.js ./sendNotify_diy.js
sed -i "s/desp += author/\/\/desp += author/g" ./sendNotify.js
sed -i "/text = text.match/a   var fs = require('fs');fs.appendFile(\"./\" + \"$NOTIFY_CONF\", text + \"\\\n\", function(err) {if(err) {return console.log(err);}});fs.appendFile(\"./\" + \"$NOTIFY_CONF\", desp + \"\\\n\", function(err) {if(err) {return console.log(err);}});\n  return" ./sendNotify.js

num=0
for jk in ${JK_LIST[*]}
do 
  cp  -rf ~/scripts ~/scripts${num}
  cd ~/scripts${num}
  sed -i 's/let CookieJDs/let CookieJDss/g' ./jdCookie.js
  sed -i "1i\let CookieJDs = [ '$jk', ]" ./jdCookie.js
  now=`date +%s%N` && delay=`echo "scale=3;$((nextdate-now))/1000000000" | bc`
  ([ $nextdate -gt $now ] && echo "未到当天${timer}，等待${delay}秒" && sleep $delay; node ./$SCRIPT | grep -Ev "pt_pin|pt_key") &
  cd ~
  num=$((num + 1))
done
unset IFS
wait

#判断是否需要特别推送
specify_send(){
  ret=`cat $1 | grep "提醒\|已超时\|已可兑换"`
  [ -n "$ret" ] && echo 1 || echo 0
}

# 清空文件
echo "" > ~/${NOTIFY_CONF}
echo "" > ~/${NOTIFY_CONF}spec
# 整合推送消息和助力码
for n in `seq 1 ${#JK_LIST[*]}`
do
    cd ~/scripts${n}
    if [ -e "./${NOTIFY_CONF}" ]; then
        if [ $(specify_send ./${NOTIFY_CONF}) -eq 0 ];then
            echo "" >> ~/${NOTIFY_CONF}
            cat ./${NOTIFY_CONF}  | tail -n +2 | sed "s/账号[0-9]/账号$n/g" >> ~/${NOTIFY_CONF}
        else
            echo "" >> ~/${NOTIFY_CONF}spec
            cat ./${NOTIFY_CONF}  | tail -n +2 | sed "s/账号[0-9]/账号$n/g" >> ~/${NOTIFY_CONF}spec
        fi
    fi
    [ -e "./${NOTIFY_CONF}" -a ! -e "~/${NOTIFY_CONF}name" ] && cat ./${NOTIFY_CONF} | head -n 1 > ~/${NOTIFY_CONF}name 
done

cd ~/scripts
echo "推送消息"
[ "$(cat ~/${NOTIFY_CONF}name | tail -n 1)"x = ""x ] && sed -i '$d' ~/${NOTIFY_CONF}name
if [ -e ~/${NOTIFY_CONF} ]; then
    # 删除连续空行为一行
    sed -i '/^$/{N;/\n$/d}' ~/${NOTIFY_CONF}
    #清除文首文末空行
    [ "$(cat ~/${NOTIFY_CONF} | head -n 1)"x = ""x ] && sed -i '1d' ~/${NOTIFY_CONF}
    [ "$(cat ~/${NOTIFY_CONF} | tail -n 1)"x = ""x ] && sed -i '$d' ~/${NOTIFY_CONF}
    cp -f ./sendNotify_diy.js ./sendNotify.js
    sed -i "s/text = text.match/\/\/text = text.match/g" ./sendNotify.js
    node ./run_sendNotify.js
    rm -f ./${NOTIFY_CONF}
    rm -f ~/${NOTIFY_CONF}
fi
# 特殊推送
if [ -e ~/${NOTIFY_CONF}spec ]; then
    # 删除连续空行为一行
    sed -i '/^$/{N;/\n$/d}' ~/${NOTIFY_CONF}spec
    #清除文首文末空行
    [ "$(cat ~/${NOTIFY_CONF}spec | head -n 1)"x = ""x ] && sed -i '1d' ~/${NOTIFY_CONF}spec
    [ "$(cat ~/${NOTIFY_CONF}spec | tail -n 1)"x = ""x ] && sed -i '$d' ~/${NOTIFY_CONF}spec
    cp -f ./sendNotify_diy.js ./sendNotify.js
    sed -i "s/text = text.match/\/\/text = text.match/g" ./sendNotify.js
    sed -i "s/process.env.DD_BOT_TOKEN/process.env.DD_BOT_TOKEN_SPEC/g" ./sendNotify.js
    sed -i "s/process.env.DD_BOT_SECRET/process.env.DD_BOT_SECRET_SPEC/g" ./sendNotify.js
    node ./run_sendNotify_spec.js
    rm -f ~/${NOTIFY_CONF}spec
fi
# 恢复原文件
cp -f ./sendNotify_diy.js ./sendNotify.js
