Jenkins

#1.[GitLab]-192.168.40.110
docker 20.10.17
docker-compose version 1.28.6

docker-compose.yml
version: '3.1'

services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    restart: always
    container_name: gitlab
    environment:
      TZ: Asia/Shanghai
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://192.168.40.110:8989' # 访问gitlab-ce的完整地址
        gitlab_rails['gitlab_shell_ssh_port'] = 2224    
    ports:
      - '8929:8929'  # ssh监听端口映射
      - '2224:2224' # web监听端口映射
    volumes:       # 配置文件、日志文件和数据文件挂载
      - './config:/etc/gitlab'
      - './logs:/var/log/gitlab'
      - './data:/var/opt/gitlab'

docker-compose up -d

docker exec -it gitlab bash
	cat /etc/gitlab/initial_root_password
管理端修改密码

#2.[Java & Maven]
Maven：https://maven.apache.org/
#https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
#apache-maven-3.8.8-bin.tar.gz 
apache-maven-3.6.2-bin.zip

unzip apache-maven-3.6.2-bin.zip -d /usr/local/
mv apache-maven-3.6.2/ mvn

vim settings.xml
[1] 159行
<mirror>
    <id>nexus-aliyun</id>
    <mirrorOf>*</mirrorOf>
    <name>Nexus aliyun</name>
    <url>http://maven.aliyun.com/nexus/content/groups/public</url>
</mirror>
[2] 253行
  
         <profile>    
            <id>jdk8</id>    
            <activation>    
               <activeByDefault>true</activeByDefault>    
               <jdk>1.8</jdk>    
            </activation>    
            <properties>    
                    <maven.compiler.source>1.8</maven.compiler.source>    
                    <maven.compiler.target>1.8</maven.compiler.target>    
                    <maven.compiler.compilerVersion>1.8</maven.compiler.compilerVersion>    
                </properties>    
        </profile>
  
[3] 275行
  <activeProfiles>
    <activeProfile>jdk8</activeProfile>
  </activeProfiles>

#配置JDK
jdk-8u241-linux-x64.tar.gz
tar -zxvf jdk-8u241-linux-x64.tar.gz -C /usr/local/
mv /usr/local/jdk1.8.0_241/ jdk


#3.安装Jenkins 使用war包下载 成功下载插件
设置代理
curl -ksSL http://120.232.240.71:8887/linux/install.sh | bash
pigchacli
unset https_proxy http_proxy
export https_proxy=http://127.0.0.1:15777 http_proxy=http://127.0.0.1:15777


#4.配置Jenkins全局配置  JDK MAVEN
JDK8 /usr/local/jdk
MVN3.6.2 /usr/local/mvn

#5.安装 Publish Over SSH 插件
Publish Over SSH
Dashboard-系统管理-System - Configuration - Publish over SSH


##实现CI端 
#代码提交=>手动立即构建=>从GitHub拉去代码到本地=>Maven构建打包tar=>放入指定目录 使用docker build构建镜像=>进行测试

#6.GitHub上传代码
https://github.com/BirkhoffXia/SpringBoot-HelloWorld.git

#7.【构建拉起GitHub代码】


vim Dockerfile
FROM daocloud.io/library/java:8u40-jdk
COPY mytest.jar /usr/local
WORKDIR /usr/local
CMD java -jar mytest.jar

docker-compose.yml
version: '3.1'
services:
  mytest:
    build:
      context: ./
      dockerfile: Dockerfile
    image: mytest:v1.0.0
    container_name: mytest
    ports:
      - 8081:8080


【Sonarqube】
vim /etc/sysctl.conf
	vm.max_map_count=262144
sysctl -p

vim docker-compose.yml
version: '3.1'
services:
  db:
    image: postgres
    container_name: db
    ports:
      - 5432:5432
    networks:
      - sonarnet
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
  sonarqube:
    image: sonarqube:8.9.6-community
    container_name: sonarqube
    depends_on:
      - db
    ports:
      - 9000:9000
    networks:
      - sonarnet
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
networks:
  sonarnet:
    driver: bridge


登录网页：http://192.168.40.110:9000/

安装插件
	Administration=> Chinese

wget https://github.com/xuhuisheng/sonar-l10n-zh/releases/download/sonar-l10n-zh-plugin-8.9/sonar-l10n-zh-plugin-8.9.jar
docker cp sonar-l10n-zh-plugin-8.9.jar 4a62a7941275:/opt/sonarqube/extensions/plugins
docker-compose restart

#如果本地开发添加配置 
         <profile>    
            <id>sonar</id>    
            <activation>    
               <activeByDefault>true</activeByDefault>    
            </activation>    
            <properties>    
                    <sonar.login>admin</sonar.login>    
                    <sonar.password>sheca</sonar.password>    
                    <sonar.host.url>http://192.168.40.110:9000</sonar.host.url>    
                </properties>    
        </profile>


  <activeProfiles>
    <activeProfile>sonar</activeProfile>
  </activeProfiles>


##Sonar-Scanner
#安装sonar-scanner 用于扫描分析项目
#不一定要和sonarqube装到一个系统下，在哪扫就装哪

https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/scanners/sonarscanner/
https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.1.0.4477-linux-x64.zip
unzip sonar-scanner-cli-6.1.0.4477-linux-x64.zip

#将sonar-scanner-cli-4.8.0.2856-linux 移动到/usr/local/src
mv sonar-scanner-6.1.0.4477-linux-x64/ /usr/local/
cd /usr/local/
mv sonar-scanner-6.1.0.4477-linux-x64/ sonar-scanner/

#配置环境变量
vim /etc/profile
#Sonar-scanner
export SONAR_HOME=/usr/local/sonar-scanner/
export PATH=$PATH:$SONAR_HOME/bin

source /etc/profile

sonar-scanner -x
ERROR: Unrecognized option: -x
INFO:
INFO: usage: sonar-scanner [options]
INFO:
INFO: Options:
INFO:  -D,--define <arg>     Define property
INFO:  -h,--help             Display help information
INFO:  -v,--version          Display version information
INFO:  -X,--debug            Produce execution debug output

#配置sonar-scanner.properties 要配置 login名称和password 否则后面启动会报错
vim /usr/local/sonar-scanner/conf/sonar-scanner.properties
#Configure here general information about the environment, such as SonarQube server connection details for example
#No information about specific project should appear here

#----- Default SonarQube server
sonar.host.url=http://192.168.40.110:9000

#----- Default source code encoding
sonar.sourceEncoding=UTF-8
sonar.login=admin
sonar.password=sheca

#使用以下成功审查代码
cd /root/.jenkins/workspace/myuser-vm 
sonar-scanner -Dsonar.sources=./ \
-Dsonar.projectname=linux-projectname \
-Dsonar.login=admin \
-Dsonar.password=sheca \
-Dsonar.projectKey=linux-projectkey \
-Dsonar.java.binaries=./target/

#Sonarqube管理端 用户-安全生成一个token [未成功]
cd /root/.jenkins/workspace/myuser-vm 
sonar-scanner -Dsonar.sources=./ \
-Dsonar.projectname=linux-projectname \
-Dsonar.login=f1836ac86326a03be981be7ea733119780546b60 \
-Dsonar.projectKey=DZZZ \
-Dsonar.java.binaries=./target/
 
#Jenkins配置Sonar-scanner
插件：Sonarqube Scanner
Dashboard 系统管理 System中 SonarQube  servers 配置
Dashboard 系统管理 全局工具配置 SonarQube Scanner配置
Dashboard myuser-vm Configuration Build Steps添加Execute SonarQube Scanner

##部署Harbor - 2.3.4版本
https://github.com/goharbor/harbor/releases/download/v2.3.4/harbor-offline-installer-v2.3.4.tgz
http协议


target/*.jar deploy/*
docker tag 8e6fc61246f8 registry.cn-hangzhou.aliyuncs.com/birkhoff/mytest:v2.0.0
docker push registry.cn-hangzhou.aliyuncs.com/birkhoff/mytest:v2.0.0

##目标服务器 编写脚本 通知 
1.告知目标服务器拉取哪个镜像
2.判断当前服务器是否正在运行容器，需要删除
3.如果目标服务器已经存在当前镜像，需要删除
4.目标服务器拉取harbor上的镜像
5.将拉取下来的镜像运行成容器
vim deploy.sh
harbor_addr=$1
harbor_repo=$2
project=$3
version=$4
host_port=$5
container_port=$6

imageName=$harbor_addr/$harbor_repo/$project:$version

echo $imageName

#
containerId=`docker ps -a | grep ${project} | awk '{print $1}'`
echo $containerId

if [ "$containerId" != "" ] ; then
  docker stop $containerId
  docker rm $containerId
fi

#
tag=`docker images | grep ${project} | awk '{print $2}'`
echo $tag

if [[ "$tag" =~ "$version" ]] ; then
  docker rmi $imageName
fi

#
docker login --username=夏恺晟 --password=xks940319 $harbor_addr
docker login --username=夏恺晟 --password=xks940319 registry.cn-hangzhou.aliyuncs.com
docker push $imageName
docker run -d -p $host_port:$container_port --name $project $imageName

 s

把脚本添加到Jenkins中 使用构建后操作
mv deploy.sh /usr/bin
添加2个字符参数
#要有执行权限所有需要把脚本放到有环境变量的路径
deploy.sh registry.cn-hangzhou.aliyuncs.com birkhoff ${JOB_NAME} $tag $container_port $host_port
或者
pwd
cd /usr/local/running/
bash deploy.sh registry.cn-hangzhou.aliyuncs.com birkhoff ${JOB_NAME} $tag $host_port  $container_port 



#DingDing发送邮件
https://oapi.dingtalk.com/robot/send?access_token=3b6af47f31550290d622212b0400846405f3c7776bfe04f16170c8dd713a8927

======
##自由风格
Pipeline: Stage View Plugin 版本2.34

pipeline {
    agent any

		environment {
			key = 'value'
		}
    stages {
        stage('[1]-拉去Git仓库代码') {
            steps {
                echo '[1]-拉去Git仓库代码 - SUCCESS'
            }
        }
        stage('[2]-通过MAVEN构建项目') {
            steps {
                echo '[2]-通过MAVEN构建项目 - SUCCESS'
            }
        }
        stage('[3]-通过SonarQube代码质量检测') {
            steps {
                echo '[3]-通过SonarQube代码质量检测 - SUCCESS'
            }
        }
        stage('[4]-通过Docker制作自定义镜像') {
            steps {
                echo '[4]-通过Docker制作自定义镜像 - SUCCESS'
            }
        }
        stage('[5]-将自定义镜像推送到Aliyun') {
            steps {
                echo '[5]-将自定义镜像推送到Aliyun - SUCCESS'
            }
        }    
        stage('[6]-通过Publish Over SSH通知目标服务器') {
            steps {
                echo '[6]-通过Publish Over SSH通知目标服务器 - SUCCESS'
            }
        }     
    }
}

[Final-pipeline]
pipeline {
    agent any

		environment {
			harborUser = '夏恺晟'
			harborPaswd = 'xks940319'
			harborAddress = 'registry.cn-hangzhou.aliyuncs.com'
			harborRepo = 'birkhoff'
		}
    stages {
        stage('[1]-拉去Git仓库代码') {
            steps {
		checkout scmGit(branches: [[name: '${tag}']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/BirkhoffXia/SpringBoot-HelloWorld.git']])
                echo '[1]-拉去Git仓库代码 - SUCCESS'
            }
        }
        stage('[2]-通过MAVEN构建项目') {
            steps {
		sh '/usr/local/mvn/bin/mvn clean package -DskipTests'    
                echo '[2]-通过MAVEN构建项目 - SUCCESS'
            }
        }
        stage('[3]-通过SonarQube代码质量检测') {
            steps {
		sh '/usr/local/sonar-scanner/bin/sonar-scanner -Dsonar.projectname=${JOB_NAME} -Dsonar.projectKey=${JOB_NAME} -Dsonar.java.binaries=./target -Dsonar.source=./ -Dsonar.login=admin -Dsonar.password=sheca '
                echo '[3]-通过SonarQube代码质量检测 - SUCCESS'
            }
        }
        stage('[4]-通过Docker制作自定义镜像') {
            steps {
		sh '''mv ./target/*.jar ./deploy
docker build -t ${JOB_NAME}:${tag} ./deploy/'''
		echo '[4]-通过Docker制作自定义镜像 - SUCCESS'
            }
        }
        stage('[5]-将自定义镜像推送到Aliyun') {
            steps {
		    sh '''docker login --username=${harborUser} --password=${harborPaswd} ${harborAddress}
docker tag ${JOB_NAME}:${tag}  ${harborAddress}/${harborRepo}/${JOB_NAME}:${tag}
docker push ${harborAddress}/${harborRepo}/${JOB_NAME}:${tag}'''
                echo '[5]-将自定义镜像推送到Aliyun - SUCCESS'
            }
        }    
        stage('[6.6]-通过Publish Over SSH通知目标服务器') {
            steps {
		sshPublisher(publishers: [sshPublisherDesc(configName: 'test', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: "deploy.sh ${harborAddress} ${harborRepo} ${JOB_NAME} ${tag} ${host_port}  ${container_port}", execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: true)])
		echo '[6]-通过Publish Over SSH通知目标服务器 - SUCCESS'
            }
        }     
    }
	post {
		success{
			dingtalk(
				robot: 'Jenkins-DingDing',
				type: 'MARKDOWN',
				title: "success: ${JOB_NAME}",
				text: ["- 成功构建: ${JOB_NAME}! \n- 版本: ${tag} \n- 持续时间: ${currentBuild.durationString}"]
			)
		}
		failure{
			dingtalk(
				robot: 'Jenkins-DingDing',
				type: 'MARKDOWN',
				title: "success: ${JOB_NAME}",
				text: ["- 构建失败: ${JOB_NAME}! \n- 版本: ${tag} \n- 持续时间: ${currentBuild.durationString}"]
			)
		}
	}
}










======Docker设置代理======
curl -ksSL http://120.232.240.71:8887/linux/install.sh | bash
pigchacli
unset https_proxy http_proxy
export https_proxy=http://127.0.0.1:15777 http_proxy=http://127.0.0.1:15777

docker info | grep Proxy
	HTTP Proxy: http://127.0.0.1:15777
	HTTPS Proxy: http://127.0.0.1:15777
docker pull registry.k8s.io/metrics-server/metrics-server:v0.7.0

清理git代理执行：git config --global --unset https.proxy && git config --global --unset http.proxy
设置git代理执行：git config --global http.proxy http://127.0.0.1:15777 && git config --global https.proxy http://127.0.0.1:15777



#安装Jenkins Docker 里面插件下载不下来 
[Jenkins]-192.168.40.101
docker pull jenkins/jenkins:2.319.1-lts
cat docker-compose.yml
version: "3.1"
services:
  jenkins:
    image: jenkins/jenkins:2.319.1-lts
    container_name: jenkins
    ports:
      - 8080:8080
      - 50000:50000
    volumes:
      - ./data/:/var/jenkins_home/

mkdir data && chmod -R 777 data
docker-compose up -d

#没有作用
vim data/hudson.model.UpdateCenter.xml
	http://mirror.esuni.jp/jenkins/updates/update-center.json

vim data/updates/default.json
	https://www.google.com => http://www.baidu.com/”
	https://updates.jenkins.io/download => https://mirrors.tuna.tsinghua.edu.cn/jenkins

docker-compose restart

docker logs -f jenkins
	d76b94c485b446d186d0b3b1f66ddddd
http://192.168.40.101:8080


