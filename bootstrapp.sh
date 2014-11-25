#!/bin/bash

AMAZON_MIRROR_URL=http://s3.amazonaws.com
APACHE_MIRROR_URL=http://mirrors.sonic.net/apache

ANT_VERSION=1.9.4
ANT_URL=$APACHE_MIRROR_URL/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz

CASSANDRA_VERSION=2.0.9
CASSANDRA_URL=$APACHE_MIRROR_URL/cassandra/$CASSANDRA_VERSION/apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz

EC2_API_TOOLS_VERSION="(latest)"
EC2_API_TOOLS_URL=$AMAZON_MIRROR_URL/ec2-downloads/ec2-api-tools.zip

ELASTICSEARCH_VERSION=1.3.2
ELASTICSEARCH_URL=https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$ELASTICSEARCH_VERSION.zip

EMR_CLI_VERSION="(latest)"
EMR_CLI_URL=$AMAZON_MIRROR_URL/elasticmapreduce/elastic-mapreduce-ruby.zip

GO_VERSION=1.3.1

if [ `uname` = 'Linux' ] ; then
  GO_URL=http://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
elif [ `uname` = 'Darwin' ] ; then
  GO_URL=http://golang.org/dl/go${GO_VERSION}.darwin-amd64-osx10.8.tar.gz
fi

KAFKA_VERSION=0.8.1.1
KAFKA_URL=$APACHE_MIRROR_URL/kafka/$KAFKA_VERSION/kafka_2.9.2-$KAFKA_VERSION.tgz

MAVEN_VERSION=3.1.1
MAVEN_URL=$APACHE_MIRROR_URL/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

MONGO_VERSION=2.4.10

if [ `uname` = 'Linux' ] ; then
  MONGO_URL=http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGO_VERSION.tgz
elif [ `uname` = 'Darwin' ] ; then
  MONGO_URL=http://fastdl.mongodb.org/osx/mongodb-osx-x86_64-$MONGO_VERSION.tgz
fi

RDS_CLI_VERSION="(latest)"
RDS_CLI_URL=$AMAZON_MIRROR_URL/rds-downloads/RDSCli.zip

REDIS_VERSION=2.8.13
REDIS_URL=http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz

SCALA_VERSION=2.10.4
SCALA_URL=http://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz

SPARK_VERSION=1.0.2
SPARK_URL=$APACHE_MIRROR_URL/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.tgz

function untar_download() {
  /usr/bin/curl -L -s $1 | tar xz
}

function unzip_download() {
  TMP_FILE=/tmp/download.zip
  /usr/bin/curl -L -s $1 > $TMP_FILE
  unzip -q $TMP_FILE
  rm -f $TMP_FILE
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

  rm -rf $LONG_NAME*

  if [ "$ARCHIVE_TYPE" = "zip" ] ; then
    unzip_download $URL
  else
    untar_download $URL
  fi

  if [ "$SHORT_NAME" != "" ] ; then
    ln -s $LONG_NAME* $SHORT_NAME
  fi
}

function bootstrap_cassandra() {
  bootstrap cassandra apache-cassandra $CASSANDRA_URL

  mkdir -p cassandra/data
  cd cassandra/data
  cassandra_data_dir=`pwd`
  cd ../..

  if [ `uname` = 'Linux' ] ; then
    SED_OPTS="-i.bak -e"
  elif [ `uname` = 'Darwin' ] ; then
    SED_OPTS="-i .bak -e"
  fi

  sed $SED_OPTS "s#/var/#$cassandra_data_dir/var/#g" cassandra/conf/*.*
  sed $SED_OPTS "s#-Xss180k#-Xss228k#g" cassandra/conf/*.*
}

function bootstrap_emr_cli() {
  URL=$1

  rm -rf emr-cli
  mkdir emr-cli
  cd emr-cli

  unzip_download $URL

  cd ..
}

function bootstrap_redis() {
  bootstrap redis redis $REDIS_URL

  cd redis
  make
}

function usage() {
  WIDTH=20
  echo "$0 <bootstrapp option> [<bootstrapp option>...]"
  echo ""
  echo "  Bootstrapp option $(printf %${WIDTH}s "Version") URL"
  echo "  ----------------- $(printf %${WIDTH}s "-------") ---"
  echo "  ant               $(printf %${WIDTH}s $ANT_VERSION) $ANT_URL"
  echo "  cassandra         $(printf %${WIDTH}s $CASSANDRA_VERSION) $CASSANDRA_URL"
  echo "  ec2-api-tools     $(printf %${WIDTH}s $EC2_API_TOOLS_VERSION) $EC2_API_TOOLS_URL"
  echo "  elasticsearch     $(printf %${WIDTH}s $ELASTICSEARCH_VERSION) $ELASTICSEARCH_URL"
  echo "  emr-cli           $(printf %${WIDTH}s $EMR_CLI_VERSION) $EMR_CLI_URL"
  echo "  go                $(printf %${WIDTH}s $GO_VERSION) $GO_URL"
  echo "  kafka             $(printf %${WIDTH}s $KAFKA_VERSION) $KAFKA_URL"
  echo "  maven             $(printf %${WIDTH}s $MAVEN_VERSION) $MAVEN_URL"
  echo "  mongo             $(printf %${WIDTH}s $MONGO_VERSION) $MONGO_URL"
  echo "  rds-cli           $(printf %${WIDTH}s $RDS_CLI_VERSION) $RDS_CLI_URL"
  echo "  redis             $(printf %${WIDTH}s $REDIS_VERSION) $REDIS_URL"
  echo "  scala             $(printf %${WIDTH}s $SCALA_VERSION) $SCALA_URL"
  echo "  spark             $(printf %${WIDTH}s $SPARK_VERSION) $SPARK_URL"

  exit 1
}

if [ $# = 0 ] ; then
  usage
fi

for download in "$@" ; do
  if [ "$download" = "ant" ] ; then
    bootstrap ant apache-ant $ANT_URL
  elif [ "$download" = "cassandra" ] ; then
    bootstrap_cassandra
  elif [ "$download" = "ec2-api-tools" ] ; then
    bootstrap ec2-api-tools ec2-api-tools- $EC2_API_TOOLS_URL
  elif [ "$download" = "elasticsearch" ] ; then
    bootstrap elasticsearch elasticsearch $ELASTICSEARCH_URL
  elif [ "$download" = "emr-cli" ] ; then
    bootstrap_emr_cli $EMR_CLI_URL
  elif [ "$download" = "go" ] ; then
    bootstrap "" go $GO_URL
  elif [ "$download" = "kafka" ] ; then
    bootstrap kafka kafka $KAFKA_URL
  elif [ "$download" = "maven" ] ; then
    bootstrap maven apache-maven $MAVEN_URL
  elif [ "$download" = "mongo" ] ; then
    bootstrap mongo mongo $MONGO_URL
  elif [ "$download" = "rds-cli" ] ; then
    bootstrap rds-cli RDSCli- $RDS_CLI_URL
  elif [ "$download" = "redis" ] ; then
    bootstrap_redis
  elif [ "$download" = "scala" ] ; then
    bootstrap scala scala $SCALA_URL
  elif [ "$download" = "spark" ] ; then
    bootstrap spark spark $SPARK_URL
  else
    usage
  fi
done
