#!/bin/bash
# Version: v2.61
# 

SCRIPT="$1"
# VIP人数，默认前面的人
VIPS="10"
SCRIPT_NAME=`echo "${1}" | awk -F "." '{print $1}'`
LOG="${SCRIPT_NAME}.log"
NOTIFY_CONF="dt.conf"
REPO_URL="https://github.com/tracefish/ds"
REPO_BRANCH="sc"
# 防止action抽风，加双引号不能输出home目录
home=`echo ~`
# 助力码文件目录
SHCD_DIR="${home}/ds"
# 脚本文件初始目录
SCRIPT_DIR="${home}/scripts"

[ ! -d ${SHCD_DIR} ] && git clone -b "$REPO_BRANCH" $REPO_URL ${SHCD_DIR}

# 格式化助力码
autoHelp(){
# $1 脚本文件
# $2 助力码文件所在
    cd ${SCRIPT_DIR}
    sr_file=$1
    sc_file=$2
    sc_list=(`cat "$sc_file" | while read LINE; do echo $LINE; done | awk -F "】" '{print $2}'`)
    sc_vip_list=(`echo ${sc_list[*]:0:VIPS}`)
    nums_of_user=`echo ${#sc_list[*]}`
    sc_normal_list=(`echo ${sc_list[*]:VIPS:nums_of_user}`)
    f_shcode=""
    IFS=$'\n'
	if [ -n `echo "$JD_COOKIE" | grep "&"` ]; then
		JK_LIST=(`echo "$JD_COOKIE" | awk -F "&" '{for(i=1;i<=NF;i++) print $i}'`)
	else
		JK_LIST=(`echo "$JD_COOKIE" | awk -F "$" '{for(i=1;i<=NF;i++){{if(length($i)!=0) print $i}}'`)
	fi
    if [ -n "$JK_LIST" ]; then
        diff=$((${#JK_LIST[*]}-$nums_of_user))
        for e in `seq 1 $diff`
        do 
            sc_list+=(${sc_list[0]})
            unset sc_list[0]
            sc_list=(${sc_list[*]})
            f_shcode="$f_shcode""'""`echo ${sc_list[*]:0} | awk '{for(i=1;i<=NF;i++) {if(i==NF) printf $i;else printf $i"@"}}'`""',""\n"
        done
    fi
    # 优先为vip用户助力
    for e in `seq 1 $nums_of_user`
    do 
    	if [ $((VIPS-0)) -ge $e ]; then
		sc_vip_list+=(${sc_vip_list[0]})
		unset sc_vip_list[0]
		sc_vip_list=(${sc_vip_list[*]})
	else
		sc_normal_list+=(${sc_normal_list[0]})
		unset sc_normal_list[0]
		sc_normal_list=(${sc_normal_list[*]})
	fi
	final_sc_list=(`echo ${sc_vip_list[*]} ${sc_normal_list[*]}`)
        f_shcode="$f_shcode""'""`echo ${final_sc_list[*]:0} | awk '{for(i=1;i<=NF;i++) {if(i==NF) printf $i;else printf $i"@"}}'`""',""\n"
    done
 
    unset IFS
    [ -n "$MY_SHARECODES" ] && f_shcode="$f_shcode""'$MY_SHARECODES',\n"
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
    echo "${1}：收集新助力码"
    code=`sed -n '/'码】'.*/'p ${1}`
    if [ -z "$code" ]; then
        activity=`sed -n '/配置文件.*/'p "${LOG}" | awk -F "获取" '{print $2}' | awk -F "配置" '{print $1}'`
        name=(`sed -n '/'【京东账号'.*/'p "${LOG}" | grep "开始" | awk -F "开始" '{print $2}' |sed 's/】/（/g'| awk -v ac="$activity" -F "*" '{print $1"）" ac "好友助力码】"}'`)
        # 相邻重复去重
	code=(`sed -n '/'您的好友助力码为'.*/'p ${1} | awk '{print $2}' | uniq`)
        [ -z "$code" ] && code=(`sed -n '/'好友助力码'.*/'p ${1} | awk -F "：" '{print $2}' | uniq`)
        [ -z "$code" ] && exit 0
        for i in `seq 0 $((${#name[*]}-1))`
        do 
            [ -n "${code[i]}" ] && echo "${name[i]}""${code[i]}" >> ./${LOG}1
        done
    else
        echo $code | awk '{for(i=1;i<=NF;i++)print $i}' > ./${LOG}1
    fi
}

upload_code(){
# $1：克隆仓库目录
# $2：助力码文件
# $3：仓库本地助力码文件
	[ ! -e $2 -o -z "$GITHUB_TOKEN" ] && echo "退出脚本" && exit 0

	echo "上传助力码文件"
	cd $1
	echo "拉取最新源码"
	git config --global user.email "tracefish@qq.com"
	git config --global user.name "tracefish"
	git pull origin "$REPO_BRANCH:$REPO_BRANCH"
	
	echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
	sudo git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
	
	echo "强制覆盖原文件"
	mv -v $2 $3
	git add .
	git commit -m "update ${SCRIPT_NAME} `date +%Y%m%d%H%M%S`" 2>/dev/null
	
	echo "Pushing changings from tmp_upstream to origin"
	sudo git push origin "$REPO_BRANCH:$REPO_BRANCH" --force
}

# 清除连续空行为一行和首尾空行
blank_lines2blank_line(){
	# $1: 文件名
    # 删除连续空行为一行
    cat -s $1 > $1.bk
    mv -f $1.bk $1
    #清除文首文末空行
    [ "$(cat $1 | head -n 1)"x = ""x ] && sed -i '1d' $1
    [ "$(cat $1 | tail -n 1)"x = ""x ] && sed -i '$d' $1
}

# 判断是否需要特别推送
specify_send(){
  ret=`cat $1 | grep "提醒\|已超时\|已可兑换\|已失效\|重新登录\|已可领取\|未选择商品\|兑换地址\|未继续领养"`
  [ -n "$ret" ] && echo 1 || echo 0
}

# 主函数
main(){
	cd ${SCRIPT_DIR}

	if [ -n "$SYNCURL" ]; then
		echo "下载脚本"
		curl "$SYNCURL" > "./$SCRIPT"
		# 外链脚本替换
		sed -i "s/indexOf('GITHUB')/indexOf('GOGOGOGO')/g" `ls -l |grep -v ^d|awk '{print $9}'`
		sed -i 's/indexOf("GITHUB")/indexOf("GOGOGOGO")/g' `ls -l |grep -v ^d|awk '{print $9}'`
	fi
	
	echo "修改发送方式"
	if [ -n "$DD_BOT_TOKEN_SPEC" -a -n "$DD_BOT_SECRET_SPEC" ]; then
	#修改常规推送
	cat > ./run_sendNotify.js <<EOF
notify = require('./sendNotify');
fs = require('fs');
var data = fs.readFileSync('./${NOTIFY_CONF}');
var name = fs.readFileSync('./${NOTIFY_CONF}name');

notify.sendNotify(name, data.toString());
EOF
	#修改特别推送
	cat > ./run_sendNotify_spec.js <<EOT
notify = require('./sendNotify');
fs = require('fs');
var data = fs.readFileSync('./${NOTIFY_CONF}spec');
var name = fs.readFileSync('./${NOTIFY_CONF}name');

notify.sendNotify(name, data.toString());
EOT
	    cp -f ./sendNotify.js ./sendNotify_diy.js
	    sed -i "s/desp += author/\/\/desp += author/g" ./sendNotify.js
	    sed -i "/text = text.match/a   var fs = require('fs');fs.appendFile(\"./\" + \"${NOTIFY_CONF}name\", text + \"\\\n\", function(err) {if(err) {return console.log(err);}});fs.exists(\"${NOTIFY_CONF}name\", function(exists) {if (exists) {fs.appendFile(\"./\" + \"${NOTIFY_CONF}spec_tmp\", desp + \"\\\n\", function(err) {if(err) {return console.log(err);}})} else {fs.appendFile(\"./\" + \"${NOTIFY_CONF}_tmp\", desp + \"\\\n\", function(err) {if(err) {return console.log(err);}})}});\n  return" ./sendNotify.js
	fi
	
	[ ! -e "./$SCRIPT" ] && echo "脚本不存在" && exit 0

	echo "替换助力码"
	[ -e "${SHCD_DIR}/${SCRIPT_NAME}.log" ] && autoHelp "${SCRIPT}" "${SHCD_DIR}/${SCRIPT_NAME}.log"

	echo "DECODE"
	sed -i "s/indexOf('GITHUB')/indexOf('GOGOGOGO')/g" ./$SCRIPT
	sed -i 's/indexOf("GITHUB")/indexOf("GOGOGOGO")/g' ./$SCRIPT
	encode_str=(`cat ./${SCRIPT} | grep "window" | awk -F "window" '{print($1)}'| awk -F "var " '{print $(NF-1)}' | awk -F "=" '{print $1}' | sort -u`)
	if [ -n "$encode_str" ]; then
		for ec in ${encode_str[*]}
		do
			sed -i "s/return $ec/if($ec.toLowerCase()==\"github\"){$ec=\"GOGOGOGO\"};return $ec/g" ./$SCRIPT
		done
	fi

	echo "开始运行"
	(node ./$SCRIPT | grep -Ev "pt_pin|pt_key") >&1 | tee ./${LOG}
	
	# 判断是否需要特别推送
	if [ -e ./${NOTIFY_CONF}_tmp -a $(specify_send ./${NOTIFY_CONF}_tmp) -eq 0 ];then
		[ -e ./${NOTIFY_CONF}_tmp ] && mv ./${NOTIFY_CONF}_tmp ./${NOTIFY_CONF}
		[ -e ./${NOTIFY_CONF}spec_tmp ] && mv ./${NOTIFY_CONF}spec_tmp ./${NOTIFY_CONF}spec
	else
		[ -e ./${NOTIFY_CONF}spec_tmp ] && mv ./${NOTIFY_CONF}spec_tmp ./${NOTIFY_CONF}
		[ -e ./${NOTIFY_CONF}_tmp ] && mv ./${NOTIFY_CONF}_tmp ./${NOTIFY_CONF}spec
	fi


	echo "推送消息"
	cp -f ./sendNotify_diy.js ./sendNotify.js
	sed -i 's/text}\\n\\n/text}\\n/g' ./sendNotify.js
	sed -i 's/\\n\\n本脚本/\\n本脚本/g' ./sendNotify.js
	sed -i  "s/text = text.match/\/\/text = text.match/g" ./sendNotify.js

	if [ -e ./${NOTIFY_CONF} -a -n "$(cat ./${NOTIFY_CONF} | sed '/^$/d')" ]; then
		blank_lines2blank_line  ./${NOTIFY_CONF}
		blank_lines2blank_line  ./${NOTIFY_CONF}name
		node ./run_sendNotify.js
	fi
	# 特殊推送
	if [ -e ./${NOTIFY_CONF}spec -a -n "$(cat ./${NOTIFY_CONF}spec | sed '/^$/d')" ]; then
		blank_lines2blank_line  ./${NOTIFY_CONF}spec
		if [ -n "$DD_BOT_TOKEN_SPEC" -a -n "$DD_BOT_SECRET_SPEC" ]; then
			sed -i "s/process.env.DD_BOT_TOKEN/process.env.DD_BOT_TOKEN_SPEC/g" ./sendNotify.js
			sed -i "s/process.env.DD_BOT_SECRET/process.env.DD_BOT_SECRET_SPEC/g" ./sendNotify.js
		fi
		node ./run_sendNotify_spec.js
	fi
	# 恢复原文件
	cp -f ./sendNotify_diy.js ./sendNotify.js
	rm -f ./${NOTIFY_CONF}*
	
	collectSharecode ./${LOG}
	upload_code "${SHCD_DIR}" ${SCRIPT_DIR}/${LOG}1 ./${LOG}
}
main
