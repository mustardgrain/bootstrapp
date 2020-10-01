#!/bin/bash -e
# shellcheck shell=bash
# shellcheck disable=SC2001

LOWER_UNAME=$(uname | tr '[:upper:]' '[:lower:]')
AMAZON_MIRROR_URL=https://s3.amazonaws.com
APACHE_MIRROR_URL=https://archive.apache.org/dist

ANT_VERSION=1.10.9
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
DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)

GO_VERSION=1.15.2
GO_URL=https://golang.org/dl/go${GO_VERSION}.${LOWER_UNAME}-amd64.tar.gz

JAVA_OS=$LOWER_UNAME

if [ "$JAVA_OS" = "darwin" ] ; then
  JAVA_OS=mac
fi

JAVA_MAIN_VERSION=8
JAVA_MINOR_VERSION=242
JAVA_BUILD=08
JAVA_VERSION=${JAVA_MAIN_VERSION}u${JAVA_MINOR_VERSION}-b${JAVA_BUILD}
JAVA_FILE_NAME_VERSION=$(echo $JAVA_VERSION | sed s/-//g)
JAVA_FILE_NAME=OpenJDK${JAVA_MAIN_VERSION}U-jdk_x64_${JAVA_OS}_hotspot_${JAVA_FILE_NAME_VERSION}.tar.gz
JAVA_URL=https://github.com/AdoptOpenJDK/openjdk${JAVA_MAIN_VERSION}-binaries/releases/download/jdk${JAVA_VERSION}/$JAVA_FILE_NAME

JMETER_VERSION=5.2.1
JMETER_URL=$APACHE_MIRROR_URL/jmeter/binaries/apache-jmeter-$JMETER_VERSION.zip

KAFKA_VERSION=2.4.1
KAFKA_URL=$APACHE_MIRROR_URL/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz

MAVEN_VERSION=3.6.3
MAVEN_URL=$APACHE_MIRROR_URL/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

NODE_VERSION=12.18.4
NODE_BINARY_EXTENSION=xz

if [ "$LOWER_UNAME" = "darwin" ] ; then
  NODE_BINARY_EXTENSION=gz
fi

NODE_URL=https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-$LOWER_UNAME-x64.tar.$NODE_BINARY_EXTENSION

PWGEN_VERSION=1.0.1
PWGEN_URL=https://github.com/kirktrue/pwgen/releases/download/v${PWGEN_VERSION}/pwgen-v${PWGEN_VERSION}-${LOWER_UNAME}-amd64

RCLONE_OS=$([[ $LOWER_UNAME = 'darwin' ]] && echo 'osx' || echo "$LOWER_UNAME")
RCLONE_VERSION=1.53.1
RCLONE_URL=https://github.com/ncw/rclone/releases/download/v$RCLONE_VERSION/rclone-v${RCLONE_VERSION}-${RCLONE_OS}-amd64.zip

TERRAFORM_VERSION=0.13.0
TERRAFORM_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${LOWER_UNAME}_amd64.zip

ZOOKEEPER_VERSION=3.6.0
ZOOKEEPER_URL=$APACHE_MIRROR_URL/zookeeper/zookeeper-$ZOOKEEPER_VERSION/apache-zookeeper-$ZOOKEEPER_VERSION-bin.tar.gz

function untar_download() {
  tmp_file=$(basename "$1")
  download "$1"

  archive_extension=${URL:(-3)}

  if [ "$archive_extension" = "tgz" ] || [ "$archive_extension" = ".gz" ] ; then
    tar_flags=xzf
  elif [ "$archive_extension" = ".xz" ] ; then
    tar_flags=xJf
  else
    echo "Unknown archive extension $archive_extension"
    exit 1
  fi

  tar $tar_flags "$tmp_file"
  rm -f "$tmp_file"
}

function unzip_download() {
  tmp_file=$(basename "$1")
  download "$1"
  unzip -q "$tmp_file"
  rm -f "$tmp_file"
}

function download() {
  src_url=$1
  tmp_file=$(basename "$src_url")
  echo "Downloading $src_url to $tmp_file"
  /usr/bin/curl -L "$src_url" > "$tmp_file"
}

function bootstrap() {
  if [ $# -ne 3 ] ; then
    echo "function bootstrap <short name> <long name> <url>"
    exit 2
  fi

  SHORT_NAME=$1
  LONG_NAME_PREFIX=$2
  URL=$3
  ARCHIVE_TYPE=${URL:(-3)}

  if [ "$SHORT_NAME" != "" ] ; then
    rm -f "$SHORT_NAME"
  fi

  if [ "$LONG_NAME_PREFIX" != "" ] ; then
    rm -rf "$LONG_NAME_PREFIX*"
  fi

  if [ "$ARCHIVE_TYPE" = "tgz" ] || [ "$ARCHIVE_TYPE" = ".gz" ] || [ "$ARCHIVE_TYPE" = ".xz" ] ; then
    untar_download "$URL"
  elif [ "$ARCHIVE_TYPE" = "zip" ] ; then
    unzip_download "$URL"
  else
    download "$URL"
  fi

  if [ "$LONG_NAME_PREFIX" != "" ] && [ "$SHORT_NAME" != "" ] ; then
    # shellcheck disable=2086
    ln -s $LONG_NAME_PREFIX* "$SHORT_NAME"
  fi
}

function bootstrap_mv_chmod() {
  SHORT_NAME=$1
  URL=$2

  rm -f "$SHORT_NAME"
  download "$URL"
  mv "$(basename "$URL")" "$SHORT_NAME"
  chmod +x "$SHORT_NAME"
}

function bootstrap_aws_cli() {
  rm -rf aws aws-cli awscli-bundle
  unzip_download "$AWS_CLI_URL"

  ./awscli-bundle/install -i "$(pwd)"/aws-cli -b "$(pwd)"/aws
  rm -rf awscli-bundle*
}

function bootstrap_rclone() {
  unzip_download "$RCLONE_URL"
  zip_name=$(basename "$RCLONE_URL")
  dir_name=${zip_name:0:${#zip_name}-4}
  mv "$dir_name"/rclone .
  rm -rf "$dir_name"
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
  echo "  node              $(printf %${WIDTH}s $NODE_VERSION) $NODE_URL"
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
    bootstrap ant apache-ant- "$ANT_URL"
  elif [ "$download" = "aws-cli" ] ; then
    bootstrap_aws_cli
  elif [ "$download" = "cassandra" ] ; then
    bootstrap "" apache-cassandra- "$CASSANDRA_URL"
  elif [ "$download" = "cockroach" ] ; then
    bootstrap "" cockroach "$COCKROACH_URL"
  elif [ "$download" = "docker-compose" ] ; then
    bootstrap_mv_chmod docker-compose "$DOCKER_COMPOSE_URL"
  elif [ "$download" = "go" ] ; then
    bootstrap "" go "$GO_URL"
  elif [ "$download" = "java" ] ; then
    bootstrap java jdk "$JAVA_URL"
  elif [ "$download" = "jmeter" ] ; then
    bootstrap jmeter apache-jmeter- "$JMETER_URL"
  elif [ "$download" = "kafka" ] ; then
    bootstrap "" kafka_ "$KAFKA_URL"
  elif [ "$download" = "maven" ] ; then
    bootstrap maven apache-maven "$MAVEN_URL"
  elif [ "$download" = "node" ] ; then
    bootstrap node node- "$NODE_URL"
  elif [ "$download" = "pwgen" ] ; then
    bootstrap_mv_chmod pwgen "$PWGEN_URL"
  elif [ "$download" = "rclone" ] ; then
    bootstrap_rclone
  elif [ "$download" = "terraform" ] ; then
    bootstrap "" terraform "$TERRAFORM_URL"
  elif [ "$download" = "zookeeper" ] ; then
    bootstrap "" apache-zookeeper- "$ZOOKEEPER_URL"
  else
    usage
  fi
done
