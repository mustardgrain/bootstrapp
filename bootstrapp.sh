#!/bin/bash

LOWER_UNAME=`echo $(uname) | tr '[:upper:]' '[:lower:]'`
AMAZON_MIRROR_URL=https://s3.amazonaws.com
APACHE_MIRROR_URL=https://archive.apache.org/dist

ANT_VERSION=1.9.7
ANT_URL=$APACHE_MIRROR_URL/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz

AWS_CLI_VERSION=latest
AWS_CLI_URL=$AMAZON_MIRROR_URL/aws-cli/awscli-bundle.zip

DOCKER_COMPOSE_VERSION=1.10.0
DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`

DOCKER_MACHINE_VERSION=0.8.2
DOCKER_MACHINE_URL=https://github.com/docker/machine/releases/download/v$DOCKER_MACHINE_VERSION/docker-machine-`uname -s`-`uname -m`

GO_VERSION=1.7.5
GO_URL=http://golang.org/dl/go${GO_VERSION}.${LOWER_UNAME}-amd64.tar.gz

JMETER_VERSION=3.0
JMETER_URL=$APACHE_MIRROR_URL/jmeter/binaries/apache-jmeter-$JMETER_VERSION.zip

MAVEN_VERSION=3.3.9
MAVEN_URL=$APACHE_MIRROR_URL/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

RUST_VERSION="(latest)"
RUST_URL=https://static.rust-lang.org/rustup.sh

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

  echo "  go                $(printf %${WIDTH}s $GO_VERSION) $GO_URL"
  echo "  jmeter            $(printf %${WIDTH}s $JMETER_VERSION) $JMETER_URL"
  echo "  maven             $(printf %${WIDTH}s $MAVEN_VERSION) $MAVEN_URL"
  echo "  rust              $(printf %${WIDTH}s $RUST_VERSION) $RUST_URL"

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
  elif [ "$download" = "go" ] ; then
    bootstrap "" go $GO_URL
  elif [ "$download" = "jmeter" ] ; then
    bootstrap jmeter apache-jmeter- $JMETER_URL
  elif [ "$download" = "maven" ] ; then
    bootstrap maven apache-maven $MAVEN_URL
  elif [ "$download" = "rust" ] ; then
    bootstrap_rust
  else
    usage
  fi
done
