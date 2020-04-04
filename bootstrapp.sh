#!/bin/bash

LOWER_UNAME=`echo $(uname) | tr '[:upper:]' '[:lower:]'`
AMAZON_MIRROR_URL=https://s3.amazonaws.com
APACHE_MIRROR_URL=https://mirrors.sonic.net/apache

ANT_VERSION=1.10.7
ANT_URL=$APACHE_MIRROR_URL/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz

AWS_CLI_VERSION=latest
AWS_CLI_URL=$AMAZON_MIRROR_URL/aws-cli/awscli-bundle.zip

CASSANDRA_VERSION=3.11.6
CASSANDRA_URL=$APACHE_MIRROR_URL/cassandra/$CASSANDRA_VERSION/apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz

COCKROACH_VERSION=19.2.5
COCKROACH_OS=$LOWER_UNAME

if [ "$COCKROACH_OS" = "darwin" ] ; then
  COCKROACH_OS=$COCKROACH_OS-10.9
fi

COCKROACH_URL=https://binaries.cockroachdb.com/cockroach-v${COCKROACH_VERSION}.${COCKROACH_OS}-amd64.tgz

DOCKER_COMPOSE_VERSION=1.25.4
DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`

GO_VERSION=1.14.1
GO_URL=https://golang.org/dl/go${GO_VERSION}.${LOWER_UNAME}-amd64.tar.gz

JAVA_OS=$LOWER_UNAME

if [ "$JAVA_OS" = "darwin" ] ; then
  JAVA_OS=mac
fi

JAVA_MAIN_VERSION=8
JAVA_MINOR_VERSION=242
JAVA_BUILD=08
JAVA_VERSION=${JAVA_MAIN_VERSION}u${JAVA_MINOR_VERSION}-b${JAVA_BUILD}
JAVA_FILE_NAME_VERSION=`echo $JAVA_VERSION | sed s/-//g`
JAVA_FILE_NAME=OpenJDK${JAVA_MAIN_VERSION}U-jdk_x64_${JAVA_OS}_hotspot_${JAVA_FILE_NAME_VERSION}.tar.gz
JAVA_URL=https://github.com/AdoptOpenJDK/openjdk${JAVA_MAIN_VERSION}-binaries/releases/download/jdk${JAVA_VERSION}/$JAVA_FILE_NAME

JMETER_VERSION=5.2.1
JMETER_URL=$APACHE_MIRROR_URL/jmeter/binaries/apache-jmeter-$JMETER_VERSION.zip

KAFKA_VERSION=2.4.1
KAFKA_URL=$APACHE_MIRROR_URL/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz

MAVEN_VERSION=3.6.3
MAVEN_URL=$APACHE_MIRROR_URL/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

PWGEN_VERSION=1.0.1
PWGEN_URL=https://github.com/kirktrue/pwgen/releases/download/v${PWGEN_VERSION}/pwgen-v${PWGEN_VERSION}-${LOWER_UNAME}-amd64

RCLONE_OS=`[[ $LOWER_UNAME = 'darwin' ]] && echo 'osx' || echo $LOWER_UNAME`
RCLONE_VERSION=1.51.0
RCLONE_URL=https://github.com/ncw/rclone/releases/download/v$RCLONE_VERSION/rclone-v${RCLONE_VERSION}-${RCLONE_OS}-amd64.zip

TERRAFORM_VERSION=0.12.24
TERRAFORM_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${LOWER_UNAME}_amd64.zip

ZOOKEEPER_VERSION=3.6.0
ZOOKEEPER_URL=$APACHE_MIRROR_URL/zookeeper/zookeeper-$ZOOKEEPER_VERSION/apache-zookeeper-$ZOOKEEPER_VERSION-bin.tar.gz

function untar_download() {
  /usr/bin/curl -L -s $1 | tar xz
}

function unzip_download() {
  TMP_FILE=/tmp/download.zip
  /usr/bin/curl -L -s $1 > $TMP_FILE
  unzip -q $TMP_FILE
  rm -f $TMP_FILE
}

function download() {
  /usr/bin/curl -L -s $1 > `basename $1`
}

function bootstrap() {
  if [ $# -ne 3 ] ; then
    echo "function bootstrap <short name> <long name> <url>"
    exit 2
  fi

  SHORT_NAME=$1
  LONG_NAME=$2
  URL=$3
  ARCHIVE_TYPE=${URL:(-3)}

  if [ "$SHORT_NAME" != "" ] ; then
    unlink $SHORT_NAME 2> /dev/null
  fi

  if [ "$LONG_NAME" != "" ] ; then
    rm -rf $LONG_NAME*
  fi

  if [ "$ARCHIVE_TYPE" = "zip" ] ; then
    unzip_download $URL
  elif [ "$ARCHIVE_TYPE" = "tgz" -o "$ARCHIVE_TYPE" = ".gz" ] ; then
    untar_download $URL
  else
    download $URL
  fi

  if [ "$LONG_NAME" != "" -a "$SHORT_NAME" != "" ] ; then
    ln -s $LONG_NAME* $SHORT_NAME
  fi
}

function bootstrap_aws_cli() {
  rm -rf aws aws-cli awscli-bundle
  INSTALL_ARGS="--install-dir=`pwd`/aws-cli --bin-location=`pwd`/aws"
  unzip_download $AWS_CLI_URL

  ./awscli-bundle/install $INSTALL_ARGS
  rm -rf awscli-bundle*
}

function bootstrap_docker_compose() {
  rm -f docker-compose
  download $DOCKER_COMPOSE_URL
  mv `basename $DOCKER_COMPOSE_URL` docker-compose
  chmod +x docker-compose
}

function bootstrap_pwgen() {
  download $PWGEN_URL
  mv `basename $PWGEN_URL` pwgen
  chmod +x pwgen
}

function bootstrap_rclone() {
  unzip_download $RCLONE_URL
  zip_name=`basename $RCLONE_URL`
  dir_name=${zip_name:0:${#zip_name}-4}
  mv $dir_name/rclone .
  rm -rf $dir_name
}

function bootstrap_terraform() {
  rm -f terraform
  unzip_download $TERRAFORM_URL
}

function usage() {
  WIDTH=20
  echo "$0 <binary> [<binary>...]"
  echo ""
  echo "  Binary            $(printf %${WIDTH}s "Version") Download URL"
  echo "  ------            $(printf %${WIDTH}s "-------") ------------"
  echo "  ant               $(printf %${WIDTH}s $ANT_VERSION) $ANT_URL"
  echo "  aws-cli           $(printf %${WIDTH}s $AWS_CLI_VERSION) $AWS_CLI_URL"
  echo "  cassandra         $(printf %${WIDTH}s $CASSANDRA_VERSION) $CASSANDRA_URL"
  echo "  cockroach         $(printf %${WIDTH}s $COCKROACH_VERSION) $COCKROACH_URL"
  echo "  docker-compose    $(printf %${WIDTH}s $DOCKER_COMPOSE_VERSION) $DOCKER_COMPOSE_URL"
  echo "  go                $(printf %${WIDTH}s $GO_VERSION) $GO_URL"
  echo "  java              $(printf %${WIDTH}s $JAVA_VERSION) $JAVA_URL"
  echo "  jmeter            $(printf %${WIDTH}s $JMETER_VERSION) $JMETER_URL"
  echo "  kafka             $(printf %${WIDTH}s $KAFKA_VERSION) $KAFKA_URL"
  echo "  maven             $(printf %${WIDTH}s $MAVEN_VERSION) $MAVEN_URL"
  echo "  pwgen             $(printf %${WIDTH}s $PWGEN_VERSION) $PWGEN_URL"
  echo "  rclone            $(printf %${WIDTH}s $RCLONE_VERSION) $RCLONE_URL"
  echo "  terraform         $(printf %${WIDTH}s $TERRAFORM_VERSION) $TERRAFORM_URL"
  echo "  zookeeper         $(printf %${WIDTH}s $ZOOKEEPER_VERSION) $ZOOKEEPER_URL"

  exit 1
}

if [ $# = 0 ] ; then
  usage
fi

for download in "$@" ; do
  if [ "$download" = "ant" ] ; then
    bootstrap ant apache-ant $ANT_URL
  elif [ "$download" = "aws-cli" ] ; then
    bootstrap_aws_cli
  elif [ "$download" = "cassandra" ] ; then
    bootstrap "" apache-cassandra $CASSANDRA_URL
  elif [ "$download" = "cockroach" ] ; then
    bootstrap "" cockroach $COCKROACH_URL
  elif [ "$download" = "docker-compose" ] ; then
    bootstrap_docker_compose
  elif [ "$download" = "go" ] ; then
    bootstrap "" go $GO_URL
  elif [ "$download" = "java" ] ; then
    bootstrap java jdk${JAVA_VERSION} $JAVA_URL
  elif [ "$download" = "jmeter" ] ; then
    bootstrap jmeter apache-jmeter- $JMETER_URL
  elif [ "$download" = "kafka" ] ; then
    bootstrap "" kafka_ $KAFKA_URL
  elif [ "$download" = "maven" ] ; then
    bootstrap maven apache-maven $MAVEN_URL
  elif [ "$download" = "pwgen" ] ; then
    bootstrap_pwgen
  elif [ "$download" = "rclone" ] ; then
    bootstrap_rclone
  elif [ "$download" = "terraform" ] ; then
    bootstrap_terraform
  elif [ "$download" = "zookeeper" ] ; then
    bootstrap "" zookeeper- $ZOOKEEPER_URL
  else
    usage
  fi
done
