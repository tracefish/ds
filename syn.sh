#!/usr/bin/env sh

set -e
get_init(){
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git config --global user.name "github-actions[bot]"
    sudo git clone https://github.com/tracefish/ds ~/tmp_ds
    sudo mkdir ~/tmp_scripts/
    sudo mv -f ~/tmp_ds/*.sh ~/tmp_scripts/
    #sudo mv -f ~/tmp_ds/*.js ~/tmp_scripts/
}

get_by_git(){
    get_init
    
    mkdir -p ~/jd_scripts/logs
    cp -f docker-compose.yml ~/jd_scripts/
    cd ~/jd_scripts/

    docker-compose up -d

    echo "git pull拉取最新代码..."
    docker exec -i jd_scripts /bin/sh -c "git clone $REPO_URL /scriptss"

    sudo cp -rf `sudo find /var/lib/docker -type d -name "scriptss" | grep merged` ~/

    cd ~/scriptss
    echo "add my shell scripts"    
    sudo cp -f ~/tmp_scripts/* ./
    sudo git add .
    sudo git commit -m "Add shell scripts"
    #UPSTREAM_REPO=`git remote -v | grep origin | grep fetch | awk '{print $2}'`
    git remote --verbose
    
    echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    sudo git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    git remote --verbose
    
    echo "Pushing changings from tmp_upstream to origin"
    sudo git push origin "${SOURCE_BRANCH}:refs/heads/${DESTINATION_BRANCH}" --force

    git remote --verbose
}

get_by_docker(){
    get_init

    docker rmi `docker images -q`
    echo "Get docker image"
    docker pull $SOURCE_IMAGE
    docker save `docker images | grep latest | grep -v grep | awk '{print $3}'` > ~/jd.tar
    [ ! -e ~/scripts ] && mkdir ~/scripts && tar xvf ~/jd.tar -C ~/scripts

    echo "Find layer"
    for file in `ls ~/scripts`
    do
      layer_size=`ls -l ~/scripts/$file 2> /dev/null | grep layer | grep -v grep | awk '{print $5}'`
      [ "$layer_size" -gt 52428800 ] && tar xvf ~/scripts/$file/layer.tar -C ~/scripts/ > /dev/null && break
    done

    cd ~/scripts/scripts/
    SOURCE_BRANCH=`git branch | awk '{print $2}'`
    UPSTREAM_REPO=`git remote -v | grep origin | grep fetch | awk '{print $2}'`
    
    echo "add my shell scripts"
    sudo cp -f ~/tmp_scripts/* ./
    sudo git add .
    sudo git commit -m "Add shell scripts"
    
    echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    git remote --verbose
    
    echo "Pushing changings from tmp_upstream to origin"
    git push origin "refs/remotes/origin/${SOURCE_BRANCH}:refs/heads/${DESTINATION_BRANCH}" --force

    git remote --verbose
}

get_by_curl(){
    home=`echo ~`
    REPO_DIR="${home}/tmp_repo"
    REPO_URL="https://github.com/${GITHUB_REPOSITORY}"
    REPO_BRANCH=${DESTINATION_BRANCH}
    git clone -b "$REPO_BRANCH" $REPO_URL ${REPO_DIR}

    cd ${REPO_DIR}
    ls ${REPO_DIR} 
    for script in `ls ${REPO_DIR} | grep ".js"`
    do
    	SCRIPT_URL="https://jdsharedresourcescdn.azureedge.net/jdresource/${script}"
	status_code=`curl -I -m 10 -o /dev/null -s -w %{http_code} ${SCRIPT_URL}`
	if [ "$status_code"x = "200"x ]; then
        	curl ${SCRIPT_URL} > ./${script}
	fi
    done
    git config --global user.email "tracefish@qq.com"
    git config --global user.name "tracefish"
	
    echo "Resetting origin to: https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    sudo git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
    
    echo "强制覆盖原文件"
    git add .
    git commit -m "update `date +%Y%m%d%H%M%S`" 2>/dev/null

    echo "Pushing changings from tmp_upstream to origin"
    sudo git push origin "$REPO_BRANCH:$REPO_BRANCH" --force
}

get_by_curl
