#!/bin/bash

LOWER_UNAME=`echo $(uname) | tr '[:upper:]' '[:lower:]'`
AMAZON_MIRROR_URL=https://s3.amazonaws.com
APACHE_MIRROR_URL=http://mirrors.sonic.net/apache

ANT_VERSION=1.9.5
ANT_URL=$APACHE_MIRROR_URL/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz

AWS_CLI_VERSION=latest
AWS_CLI_URL=$AMAZON_MIRROR_URL/aws-cli/awscli-bundle.zip

DOCKER_COMPOSE_VERSION=1.7.0
DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`

DOCKER_MACHINE_VERSION=0.7.0
DOCKER_MACHINE_URL=https://github.com/docker/machine/releases/download/v$DOCKER_MACHINE_VERSION/docker-machine-`uname -s`-`uname -m`

EC2_API_TOOLS_VERSION="(latest)"
EC2_API_TOOLS_URL=$AMAZON_MIRROR_URL/ec2-downloads/ec2-api-tools.zip

EMR_CLI_VERSION="(latest)"
EMR_CLI_URL=$AMAZON_MIRROR_URL/elasticmapreduce/elastic-mapreduce-ruby.zip

GO_VERSION=1.6
GO_URL=http://golang.org/dl/go${GO_VERSION}.${LOWER_UNAME}-amd64.tar.gz

JMETER_VERSION=3.0
JMETER_URL=http://www-us.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.zip

LIQUIBASE_VERSION=3.2.3
LIQUIBASE_URL=https://github.com/liquibase/liquibase/releases/download/liquibase-parent-$LIQUIBASE_VERSION/liquibase-$LIQUIBASE_VERSION-bin.zip

MAVEN_VERSION=3.3.9
MAVEN_URL=$APACHE_MIRROR_URL/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

MYSQL_JAR_VERSION=5.1.35
MYSQL_JAR_URL=http://central.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_JAR_VERSION/mysql-connector-java-$MYSQL_JAR_VERSION.jar

NODEJS_VERSION=4.5.0
NODEJS_URL=https://nodejs.org/dist/v$NODEJS_VERSION/node-v$NODEJS_VERSION-${LOWER_UNAME}-x64.tar.gz

PLAY_VERSION=2.2.3
PLAY_URL=http://downloads.typesafe.com/play/$PLAY_VERSION/play-$PLAY_VERSION.zip

RDS_CLI_VERSION="(latest)"
RDS_CLI_URL=$AMAZON_MIRROR_URL/rds-downloads/RDSCli.zip

RUST_VERSION="(latest)"
RUST_URL=https://static.rust-lang.org/rustup.sh

SBT_VERSION=0.13.8
SBT_URL=https://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz

SCALA_VERSION=2.10.3
SCALA_URL=http://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz

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

function bootstrap_docker_util() {
  rm -rf $1
  download $2
  mv `basename $2` $1
  chmod +x $1
}

function bootstrap_emr_cli() {
  rm -rf emr-cli
  mkdir emr-cli
  cd emr-cli

  unzip_download $EMR_CLI_URL

  cd ..
}

function bootstrap_liquibase() {
  rm -rf liquibase
  mkdir liquibase
  cd liquibase

  unzip_download $LIQUIBASE_URL
  chmod +x liquibase
  cd ..
}

function bootstrap_rust() {
  RUSTUP_ARGS="--prefix=`pwd`/rust --yes --disable-sudo"
  download $RUST_URL

  sh rustup.sh $RUSTUP_ARGS --uninstall
  rm -rf rust
  sh rustup.sh $RUSTUP_ARGS
  rm -f rustup.sh
}

function usage() {
  WIDTH=20
  echo "$0 <bootstrapp option> [<bootstrapp option>...]"
  echo ""
  echo "  Bootstrapp option $(printf %${WIDTH}s "Version") URL"
  echo "  ----------------- $(printf %${WIDTH}s "-------") ---"
  echo "  ant               $(printf %${WIDTH}s $ANT_VERSION) $ANT_URL"
  echo "  aws-cli           $(printf %${WIDTH}s $AWS_CLI_VERSION) $AWS_CLI_URL"

  if [ `uname` = 'Linux' ] ; then
  echo "  docker-compose    $(printf %${WIDTH}s $DOCKER_COMPOSE_VERSION) $DOCKER_COMPOSE_URL"
  echo "  docker-machine    $(printf %${WIDTH}s $DOCKER_MACHINE_VERSION) $DOCKER_MACHINE_URL"
  fi

  echo "  emr-cli           $(printf %${WIDTH}s $EMR_CLI_VERSION) $EMR_CLI_URL"
  echo "  go                $(printf %${WIDTH}s $GO_VERSION) $GO_URL"
  echo "  jmeter            $(printf %${WIDTH}s $JMETER_VERSION) $JMETER_URL"
  echo "  liquibase         $(printf %${WIDTH}s $LIQUIBASE_VERSION) $LIQUIBASE_URL"
  echo "  maven             $(printf %${WIDTH}s $MAVEN_VERSION) $MAVEN_URL"
  echo "  mysql-jar         $(printf %${WIDTH}s $MYSQL_JAR_VERSION) $MYSQL_JAR_URL"
  echo "  nodejs            $(printf %${WIDTH}s $NODEJS_VERSION) $NODEJS_URL"
  echo "  play              $(printf %${WIDTH}s $PLAY_VERSION) $PLAY_URL"
  echo "  rds-cli           $(printf %${WIDTH}s $RDS_CLI_VERSION) $RDS_CLI_URL"
  echo "  rust              $(printf %${WIDTH}s $RUST_VERSION) $RUST_URL"
  echo "  sbt               $(printf %${WIDTH}s $SBT_VERSION) $SBT_URL"
  echo "  scala             $(printf %${WIDTH}s $SCALA_VERSION) $SCALA_URL"

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
  elif [ "$download" = "docker-compose" ] ; then
    bootstrap_docker_util docker-compose $DOCKER_COMPOSE_URL
  elif [ "$download" = "docker-machine" ] ; then
    bootstrap_docker_util docker-machine $DOCKER_MACHINE_URL
  elif [ "$download" = "ec2-api-tools" ] ; then
    bootstrap ec2-api-tools ec2-api-tools- $EC2_API_TOOLS_URL
  elif [ "$download" = "emr-cli" ] ; then
    bootstrap_emr_cli
  elif [ "$download" = "go" ] ; then
    bootstrap "" go $GO_URL
  elif [ "$download" = "jmeter" ] ; then
    bootstrap jmeter apache-jmeter- $JMETER_URL
  elif [ "$download" = "liquibase" ] ; then
    bootstrap_liquibase
  elif [ "$download" = "maven" ] ; then
    bootstrap maven apache-maven $MAVEN_URL
  elif [ "$download" = "mysql-jar" ] ; then
    bootstrap "" "" $MYSQL_JAR_URL
  elif [ "$download" = "nodejs" ] ; then
    bootstrap "node" "node-" $NODEJS_URL
  elif [ "$download" = "play" ] ; then
    bootstrap play play $PLAY_URL
  elif [ "$download" = "rds-cli" ] ; then
    bootstrap rds-cli RDSCli- $RDS_CLI_URL
  elif [ "$download" = "rust" ] ; then
    bootstrap_rust
  elif [ "$download" = "scala" ] ; then
    bootstrap scala scala $SCALA_URL
  elif [ "$download" = "sbt" ] ; then
    bootstrap "" sbt $SBT_URL
  else
    usage
  fi
done
