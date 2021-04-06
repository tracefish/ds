#!/bin/bash
# 多账号并发,不定时
# 变量：要运行的脚本$SCRIPT
# 默认随机延迟5-12秒
set -e
SCRIPT="$1"
DELAY="$2"
LOG="${SCRIPT_NAME}.log"
SCRIPT_NAME=`echo "${1}" | awk -F "." '{print $1}'`
logDir=".."

REPO_URL="https://github.com/tracefish/ds"
REPO_BRANCH="sc"
[ ! -d ~/ds ] && git clone -b "$REPO_BRANCH" $REPO_URL ~/ds

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

# 格式化助力码到文本
format_sc2txt(){
    # $1 助力码文件
    # $2 助力码文本生成位置
    sc_file=$1
    fsr_file=$2
    #${SCRIPT_NAME}.conf
    sc_list=(`cat "$sc_file" | while read LINE; do echo $LINE; done | awk -F "】" '{print $2}'`)
    IFS=$'\n'
    for e in `seq 1 ${#sc_list[*]}`
    do 
        sc_list+=(${sc_list[0]})
        unset sc_list[0]
        sc_list=(${sc_list[*]})
        if [ $e -eq 1 ]; then
            echo ${sc_list[*]:0} | awk '{for(i=1;i<=NF;i++) {if(i==NF) printf $i;else printf $i"@"}}' > $fsr_file
        else
            echo ${sc_list[*]:0} | awk '{for(i=1;i<=NF;i++) {if(i==NF) printf $i;else printf $i"@"}}' >> $fsr_file
        fi
    done
    JK_LIST=(`echo "$JD_COOKIE" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)
    if [ -n "$JK_LIST" ]; then
        diff=$((${#JK_LIST[*]}-${#sc_list[*]}))
        for e in `seq 1 $diff`
        do 
            sc_list+=(${sc_list[0]})
            unset sc_list[0]
            sc_list=(${sc_list[*]})
            echo ${sc_list[*]:0} | awk '{for(i=1;i<=NF;i++) {if(i==NF) printf $i;else printf $i"@"}}' >> $fsr_file
        done
    fi
    unset IFS
}

autoHelp(){
# $1 脚本文件
# $2 助力码文件所在
# $3 cookie顺序
    sr_file=$1
    sc_file=$2
    jk_ordr=$3
    f_shcode=""
    
    [ ! -e "$sc_file" -a -z "$MY_SHARECODES" ] && return 0
    [ -n "$MY_SHARECODES" ] && f_shcode="$f_shcode""'$MY_SHARECODES',\n"
    
    f_shcode="$f_shcode""'""`cat $sc_file | head -n $jk_ordr | tail -n -1`""',""\n"
    
    sed -i "s/let shareCodes = \[/let shareCodes = \[\n${f_shcode}/g" "./$sr_file"
    sed -i "s/const inviteCodes = \[/const inviteCodes = \[\n${f_shcode}/g" "./$sr_file"
    sed -i "s/let inviteCodes = \[/let inviteCodes = \[\n${f_shcode}/g" "./$sr_file"
    # 修改种豆得豆
    if [ "$1" = "jd_plantBean.js" ]; then
        sed -i "s/let PlantBeanShareCodes = \[/let PlantBeanShareCodes = \[\n${f_shcode}/g" "./jdPlantBeanShareCodes.js"
    fi
    # 修改东东萌宠
    if [ "$1" = "jd_pet.js" ]; then
        sed -i "s/let PetShareCodes = \[/let PetShareCodes = \[\n${f_shcode}/g" "./jdPetShareCodes.js"
    fi
    # 修改东东农场
    if [ "$1" = "jd_fruit.js" ]; then
        sed -i "s/let FruitShareCodes = \[/let FruitShareCodes = \[\n${f_shcode}/g" "./jdFruitShareCodes.js"
    fi
    # 修改京喜工厂
    if [ "$1" = "jd_dreamFactory.js" ]; then
        sed -i "s/let shareCodes = \[/let shareCodes = \[\n${f_shcode}/g" "./jdDreamFactoryShareCodes.js"
    fi
    # 修改东东工厂
    if [ "$1" = "jd_jdfactory.js" ]; then
        sed -i "s/let shareCodes = \[/let shareCodes = \[\n${f_shcode}/g" "./jdFactoryShareCodes.js"
    fi
}

# 收集助力码
collectSharecode(){
    #$2: jk位置
    echo "${1}：收集新助力码"
    code=`sed -n '/'码】'.*/'p ${1} | grep -v "提交" | sed "s/ 账号[0-9]/账号$2/g"`
    if [ -z "$code" ]; then
        activity=`sed -n '/配置文件.*/'p "./${LOG}" | awk -F "获取" '{print $2}' | awk -F "配置" '{print $1}'`
        name=(`sed -n '/'【京东账号'.*/'p "./${LOG}" | grep "开始" | sed "s/ 账号[0-9]/账号$2/g" | awk -F "开始" '{print $2}' |sed 's/】/（/g'| awk -v ac="$activity" -F "*" '{print $1"）" ac "好友助力码】"}'`)
        code=(`sed -n '/'您的好友助力码为'.*/'p ${1} | awk '{print $2}'`)
        [ -z "$code" ] && code=(`sed -n '/'好友助力码'.*/'p ${1} | awk -F "：" '{print $2}'`)
        [ -z "$code" ] && exit 0
        for i in `seq 0 $((${#name[*]}-1))`
        do 
            echo "${name[i]}""${code[i]}" >> ./${LOG}1
        done
    else
        echo $code | awk '{for(i=1;i<=NF;i++)print $i}' > ./${LOG}1
    fi
}

echo "开始多账号并发"
IFS=$'\n'

format_sc2txt "${logDir}/ds/${SCRIPT_NAME}.log" "${logDir}/${SCRIPT_NAME}.conf"

echo "修改cookie"
sed -i 's/process.env.JD_COOKIE/process.env.JD_COOKIES/g' ./jdCookie.js
JK_LIST=(`echo "$JD_COOKIE" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)

num=1
for jk in ${JK_LIST[*]}
do
    cp  -rf ~/scripts ~/scripts${num}
    cd ~/scripts${num}
    sed -i 's/let CookieJDs/let CookieJDss/g' ./jdCookie.js
    sed -i "1i\let CookieJDs = [ '$jk', ]" ./jdCookie.js
    autoHelp "$1" "~/${SCRIPT_NAME}.conf" $num
    ((node ./${SCRIPT} | grep -Ev "pt_pin|pt_key") >&1 | tee "./${LOG}"; collectSharecode "${logDir}/${SCRIPT_NAME}.conf" $num) &
    cd ~
    # 随机延迟5-12秒
    random_time=$(($RANDOM%12+5))
    delay=${DELAY:-$random_time}
    echo "随机延迟${delay}秒"
    sleep ${delay}s
    num=$((num + 1))
done
echo "有账号" "$((num-1))"
unset IFS

wait

for n in `seq 1 $num`
do
    cd ~/scripts${num}
    [ "$i"x = "1"x ] && echo ./${LOG}1 > ~/${LOG} || echo ./${LOG}1 >> ~/${LOG}
done

cat ~/${LOG}

[ ! -e "~/${LOG}" -o -z "$(cat ~/${LOG})" ] && echo "退出脚本" && exit 0
echo "上传助力码文件"
cd ~/ds
echo "拉取最新源码"
git config --global user.email "tracefish@qq.com"
git config --global user.name "tracefish"
git pull origin "$REPO_BRANCH:$REPO_BRANCH"

echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
sudo git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"

echo "强制覆盖原文件"
mv -v ~/${LOG} ./${LOG}
git add .
git commit -m "update ${SCRIPT_NAME} `date +%Y%m%d%H%M%S`"

echo "Pushing changings from tmp_upstream to origin"
sudo git push origin "$REPO_BRANCH:$REPO_BRANCH" --force
