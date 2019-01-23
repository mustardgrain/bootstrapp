#!/bin/bash

LOWER_UNAME=`echo $(uname) | tr '[:upper:]' '[:lower:]'`
AMAZON_MIRROR_URL=https://s3.amazonaws.com
APACHE_MIRROR_URL=http://archive.apache.org/dist

ANT_VERSION=1.10.5
ANT_URL=$APACHE_MIRROR_URL/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz

AWS_CLI_VERSION=latest
AWS_CLI_URL=$AMAZON_MIRROR_URL/aws-cli/awscli-bundle.zip

CASSANDRA_VERSION=3.11.3
CASSANDRA_URL=$APACHE_MIRROR_URL/cassandra/$CASSANDRA_VERSION/apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz

COCKROACH_VERSION=2.1.2
COCKROACH_OS=$LOWER_UNAME

if [ "$COCKROACH_OS" = "darwin" ] ; then
  COCKROACH_OS=$COCKROACH_OS-10.9
fi

COCKROACH_URL=https://binaries.cockroachdb.com/cockroach-v${COCKROACH_VERSION}.${COCKROACH_OS}-amd64.tgz

DOCKER_COMPOSE_VERSION=1.23.2
DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`

DOCKER_MACHINE_VERSION=0.16.0
DOCKER_MACHINE_URL=https://github.com/docker/machine/releases/download/v$DOCKER_MACHINE_VERSION/docker-machine-`uname -s`-`uname -m`

GO_VERSION=1.11.2
GO_URL=https://golang.org/dl/go${GO_VERSION}.${LOWER_UNAME}-amd64.tar.gz

JAVA_OS=$LOWER_UNAME

if [ "$JAVA_OS" = "darwin" ] ; then
  JAVA_OS=mac
fi

JAVA_MAIN_VERSION=8
JAVA_MINOR_VERSION=202
JAVA_BUILD=08
JAVA_VERSION=${JAVA_MAIN_VERSION}u${JAVA_MINOR_VERSION}-b${JAVA_BUILD}
JAVA_FILE_NAME_VERSION=`echo $JAVA_VERSION | sed s/-//g`
JAVA_FILE_NAME=OpenJDK${JAVA_MAIN_VERSION}U-jdk_x64_${JAVA_OS}_hotspot_${JAVA_FILE_NAME_VERSION}.tar.gz
JAVA_URL=https://github.com/AdoptOpenJDK/openjdk${JAVA_MAIN_VERSION}-binaries/releases/download/jdk${JAVA_VERSION}/$JAVA_FILE_NAME

JMETER_VERSION=5.0
JMETER_URL=$APACHE_MIRROR_URL/jmeter/binaries/apache-jmeter-$JMETER_VERSION.zip

KAFKA_VERSION=2.1.0
KAFKA_URL=$APACHE_MIRROR_URL/kafka/$KAFKA_VERSION/kafka_2.12-$KAFKA_VERSION.tgz

MAVEN_VERSION=3.6.0
MAVEN_URL=$APACHE_MIRROR_URL/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

MYSQL_JAR_VERSION=5.1.47
MYSQL_JAR_URL=http://central.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_JAR_VERSION/mysql-connector-java-$MYSQL_JAR_VERSION.jar

OP_VERSION=0.5.4
OP_URL=https://cache.agilebits.com/dist/1P/op/pkg/v${OP_VERSION}/op_${LOWER_UNAME}_amd64_v${OP_VERSION}.zip

RCLONE_OS=`[[ $LOWER_UNAME = 'darwin' ]] && echo 'osx' || echo $LOWER_UNAME`
RCLONE_VERSION=1.45
RCLONE_URL=https://github.com/ncw/rclone/releases/download/v$RCLONE_VERSION/rclone-v${RCLONE_VERSION}-${RCLONE_OS}-amd64.zip

TERRAFORM_VERSION=0.11.10
TERRAFORM_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${LOWER_UNAME}_amd64.zip

ZOOKEEPER_VERSION=3.4.13
ZOOKEEPER_URL=$APACHE_MIRROR_URL/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz

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

function bootstrap_op() {
  unzip_download $OP_URL
}

function bootstrap_rclone() {
  unzip_download $RCLONE_URL
  zip_name=`basename $RCLONE_URL`
  dir_name=${zip_name:0:${#zip_name}-4}
  mv $dir_name/rclone .
  rm -rf $dir_name
}

function bootstrap_terraform() {
  unzip_download $TERRAFORM_URL
}

function usage() {
  WIDTH=20
  echo "$0 <bootstrapp option> [<bootstrapp option>...]"
  echo ""
  echo "  Bootstrapp option $(printf %${WIDTH}s "Version") URL"
  echo "  ----------------- $(printf %${WIDTH}s "--------") ---"
  echo "  ant               $(printf %${WIDTH}s $ANT_VERSION) $ANT_URL"
  echo "  aws-cli           $(printf %${WIDTH}s $AWS_CLI_VERSION) $AWS_CLI_URL"
  echo "  cassandra         $(printf %${WIDTH}s $CASSANDRA_VERSION) $CASSANDRA_URL"
  echo "  cockroach         $(printf %${WIDTH}s $COCKROACH_VERSION) $COCKROACH_URL"
  echo "  docker-compose    $(printf %${WIDTH}s $DOCKER_COMPOSE_VERSION) $DOCKER_COMPOSE_URL"
  echo "  docker-machine    $(printf %${WIDTH}s $DOCKER_MACHINE_VERSION) $DOCKER_MACHINE_URL"
  echo "  go                $(printf %${WIDTH}s $GO_VERSION) $GO_URL"
  echo "  java              $(printf %${WIDTH}s $JAVA_VERSION) $JAVA_URL"
  echo "  jmeter            $(printf %${WIDTH}s $JMETER_VERSION) $JMETER_URL"
  echo "  kafka             $(printf %${WIDTH}s $KAFKA_VERSION) $KAFKA_URL"
  echo "  maven             $(printf %${WIDTH}s $MAVEN_VERSION) $MAVEN_URL"
  echo "  mysql-jar         $(printf %${WIDTH}s $MYSQL_JAR_VERSION) $MYSQL_JAR_URL"
  echo "  op                $(printf %${WIDTH}s $OP_VERSION) $OP_URL"
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
    bootstrap_docker_util docker-compose $DOCKER_COMPOSE_URL
  elif [ "$download" = "docker-machine" ] ; then
    bootstrap_docker_util docker-machine $DOCKER_MACHINE_URL
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
  elif [ "$download" = "mysql-jar" ] ; then
    bootstrap "" "" $MYSQL_JAR_URL
  elif [ "$download" = "op" ] ; then
    bootstrap_op
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
