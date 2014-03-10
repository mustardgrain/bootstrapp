#!/bin/bash

if [ `uname` = 'Linux' ] ; then
  SED_OPTS="-i.bak -e"
elif [ `uname` = 'Darwin' ] ; then
  SED_OPTS="-i .bak -e"
fi

AMAZON_MIRROR_URL=http://s3.amazonaws.com
APACHE_MIRROR_URL=http://mirrors.sonic.net/apache
ECLIPSE_MIRROR_URL=http://ftp.ussg.iu.edu

ANT_VERSION=1.9.3
ANT_URL=$APACHE_MIRROR_URL/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz

CASSANDRA_VERSION=2.0.5
CASSANDRA_URL=$APACHE_MIRROR_URL/cassandra/$CASSANDRA_VERSION/apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz

EC2_API_TOOLS_VERSION="(latest)"
EC2_API_TOOLS_URL=$AMAZON_MIRROR_URL/ec2-downloads/ec2-api-tools.zip

_ECLIPSE_RELEASE="kepler"
_ECLIPSE_REVISION="SR1"
_ECLIPSE_MIRROR=$ECLIPSE_MIRROR_URL/eclipse/technology/epp/downloads/release/$_ECLIPSE_RELEASE/$_ECLIPSE_REVISION

ECLIPSE_VERSION="$_ECLIPSE_RELEASE-$_ECLIPSE_REVISION"

if [ `uname` = 'Linux' ] ; then
  ECLIPSE_URL=$_ECLIPSE_MIRROR/eclipse-java-$ECLIPSE_VERSION-linux-gtk-x86_64.tar.gz
elif [ `uname` = 'Darwin' ] ; then
  ECLIPSE_URL=$_ECLIPSE_MIRROR/eclipse-java-$ECLIPSE_VERSION-$_ECLIPSE_REVISION-macosx-cocoa-x86_64.tar.gz
fi

EMR_CLI_VERSION="(latest)"
EMR_CLI_URL=$AMAZON_MIRROR_URL/elasticmapreduce/elastic-mapreduce-ruby.zip

GO_VERSION=1.2.1

if [ `uname` = 'Linux' ] ; then
  GO_URL=https://go.googlecode.com/files/go${GO_VERSION}.linux-amd64.tar.gz
elif [ `uname` = 'Darwin' ] ; then
  GO_URL=https://go.googlecode.com/files/go${GO_VERSION}.darwin-amd64-osx10.8.tar.gz
fi

HADOOP_VERSION=2.3.0
HADOOP_URL=$APACHE_MIRROR_URL/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz

HBASE_VERSION=0.96.1
HBASE_URL=$APACHE_MIRROR_URL/hbase/hbase-$HBASE_VERSION/hbase-$HBASE_VERSION-hadoop2-bin.tar.gz

HIVE_VERSION=0.11.0
HIVE_URL=$APACHE_MIRROR_URL/hive/hive-$HIVE_VERSION/hive-$HIVE_VERSION-bin.tar.gz

JDK_MAJOR_VERSION=7
JDK_MINOR_VERSION=45
JDK_VERSION=${JDK_MAJOR_VERSION}u${JDK_MINOR_VERSION}
JDK_FILE="jdk-${JDK_VERSION}-linux-x64.tar.gz"
JDK_URL="http://download.oracle.com/otn-pub/java/jdk/${JDK_VERSION}-b18/$JDK_FILE"

KAFKA_VERSION=0.8.0
KAFKA_URL=$APACHE_MIRROR_URL/kafka/$KAFKA_VERSION/kafka_2.8.0-$KAFKA_VERSION.tar.gz

MAVEN_VERSION=3.1.1
MAVEN_URL=$APACHE_MIRROR_URL/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

RDS_CLI_VERSION="(latest)"
RDS_CLI_URL=$AMAZON_MIRROR_URL/rds-downloads/RDSCli.zip

REDIS_VERSION=2.8.5
REDIS_URL=http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz

SOLR_VERSION=4.6.1
SOLR_URL=$APACHE_MIRROR_URL/lucene/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz

WHIRR_VERSION=0.8.2
WHIRR_URL=$APACHE_MIRROR_URL/whirr/whirr-$WHIRR_VERSION/whirr-$WHIRR_VERSION.tar.gz

ZOOKEEPER_VERSION=3.4.5
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

function bootstrap_hadoop() {
  bootstrap hadoop hadoop- $HADOOP_URL

  mkdir -p hadoop/data
  cd hadoop/data
  hadoop_data_dir=`pwd`
  cd ../..
  hadoop_conf_dir=hadoop/etc/hadoop

  if [ `uname` = 'Linux' ] ; then
    num_cores=`cat /proc/cpuinfo | grep processor | wc -l`
  elif [ `uname` = 'Darwin' ] ; then
    num_cores=`sysctl -n hw.ncpu`
  fi

  primary_group=`id -g -n $USER`

  sed $SED_OPTS "s#\(JAVA_HOME\).*#\1=$JAVA_HOME#g" $hadoop_conf_dir/hadoop-env.sh
  sed $SED_OPTS "s/# export JAVA_HOME/export JAVA_HOME/g" $hadoop_conf_dir/hadoop-env.sh
  echo "export HADOOP_HOME_WARN_SUPPRESS=TRUE" >> $hadoop_conf_dir/hadoop-env.sh

  mv $hadoop_conf_dir/core-site.xml $hadoop_conf_dir/core-site.xml.orig
  cat > $hadoop_conf_dir/core-site.xml <<XML_DOC
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>fs.checkpoint.dir</name>
    <value>$hadoop_data_dir/dfs/namesecondary</value>
  </property>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://localhost:8020</value>
  </property>
  <property>
    <name>hadoop.proxyuser.$USER.hosts</name>
    <value>localhost</value>
  </property>
  <property>
    <name>hadoop.proxyuser.$USER.groups</name>
    <value>$primary_group</value>
  </property>
</configuration>
XML_DOC

  mv $hadoop_conf_dir/hdfs-site.xml $hadoop_conf_dir/hdfs-site.xml.orig
  cat > $hadoop_conf_dir/hdfs-site.xml <<XML_DOC
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>dfs.name.dir</name>
    <value>$hadoop_data_dir/dfs/name</value>
  </property>
  <property>
    <name>dfs.data.dir</name>
    <value>$hadoop_data_dir/dfs/data</value>
  </property>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.support.append</name>
    <value>true</value>
  </property>
  <property>
    <name>dfs.datanode.max.xcievers</name>
    <value>4096</value>
  </property>
</configuration>
XML_DOC

  cat > $hadoop_conf_dir/mapred-site.xml <<XML_DOC
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>mapred.local.dir</name>
    <value>$hadoop_data_dir/mapred/local</value>
  </property>
  <property>
    <name>mapred.job.tracker</name>
    <value>localhost:8021</value>
  </property>
  <property>
    <name>mapred.tasktracker.map.tasks.maximum</name>
    <value>$num_cores</value>
    <final>true</final>
  </property>
</configuration>
XML_DOC
}

function bootstrap_jdk() {
  rm -rf jdk
  rm -rf jdk1.${JDK_MAJOR_VERSION}*
  wget -q --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" $JDK_URL
  tar xzf $JDK_FILE
  rm -rf $JDK_FILE
  ln -s jdk1.${JDK_MAJOR_VERSION}.0_${JDK_MINOR_VERSION} jdk
}

function bootstrap_maven() {
  bootstrap maven apache-maven $MAVEN_URL

  # I'm tired of gem always complaining about the world-writable-ness of this directory
  chmod 0744 apache-maven-*
  chmod 0744 apache-maven-*/bin
}

function bootstrap_redis() {
  bootstrap redis redis $REDIS_URL

  cd redis
  make
}

function bootstrap_whirr() {
  bootstrap whirr whirr $WHIRR_URL
  
  sed $SED_OPTS "s#whirr.log#/tmp/whirr.log#" $WHIRR_HOME/conf/log4j-cli.xml
}

function bootstrap_zookeeper() {
  bootstrap zookeeper zookeeper $ZOOKEEPER_URL
  cp zookeeper/conf/zoo_sample.cfg zookeeper/conf/zoo.cfg  
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
  echo "  eclipse           $(printf %${WIDTH}s $ECLIPSE_VERSION) $ECLIPSE_URL"
  echo "  emr-cli           $(printf %${WIDTH}s $EMR_CLI_VERSION) $EMR_CLI_URL"
  echo "  go                $(printf %${WIDTH}s $GO_VERSION) $GO_URL"
  echo "  hadoop            $(printf %${WIDTH}s $HADOOP_VERSION) $HADOOP_URL"
  echo "  hbase             $(printf %${WIDTH}s $HBASE_VERSION) $HBASE_URL"
  echo "  hive              $(printf %${WIDTH}s $HIVE_VERSION) $HIVE_URL"

  if [ `uname` = "Linux" ] ; then
  echo "  jdk               $(printf %${WIDTH}s $JDK_VERSION) $JDK_URL"
  fi

  echo "  kafka             $(printf %${WIDTH}s $KAFKA_VERSION) $KAFKA_URL"
  echo "  maven             $(printf %${WIDTH}s $MAVEN_VERSION) $MAVEN_URL"
  echo "  rds-cli           $(printf %${WIDTH}s $RDS_CLI_VERSION) $RDS_CLI_URL"
  echo "  solr              $(printf %${WIDTH}s $SOLR_VERSION) $SOLR_URL"
  echo "  redis             $(printf %${WIDTH}s $REDIS_VERSION) $REDIS_URL"
  echo "  whirr             $(printf %${WIDTH}s $WHIRR_VERSION) $WHIRR_URL"
  echo "  zookeeper         $(printf %${WIDTH}s $ZOOKEEPER_VERSION) $ZOOKEEPER_URL"
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
  elif [ "$download" = "clojure" ] ; then
    bootstrap clojure clojure $CLOJURE_URL
  elif [ "$download" = "ec2-api-tools" ] ; then
    bootstrap ec2-api-tools ec2-api-tools- $EC2_API_TOOLS_URL
  elif [ "$download" = "eclipse" ] ; then
    bootstrap "" eclipse $ECLIPSE_URL
  elif [ "$download" = "emr-cli" ] ; then
    bootstrap_emr_cli $EMR_CLI_URL
  elif [ "$download" = "go" ] ; then
    bootstrap "" go $GO_URL
  elif [ "$download" = "hadoop" ] ; then
    bootstrap_hadoop
  elif [ "$download" = "hbase" ] ; then
    bootstrap hbase hbase- $HBASE_URL
  elif [ "$download" = "hive" ] ; then
    bootstrap hive hive- $HIVE_URL
  elif [ "$download" = "jdk" -a `uname` = "Linux" ] ; then
    bootstrap_jdk
  elif [ "$download" = "kafka" ] ; then
    bootstrap kafka kafka $KAFKA_URL
  elif [ "$download" = "maven" ] ; then
    bootstrap_maven
  elif [ "$download" = "rds-cli" ] ; then
    bootstrap rds-cli RDSCli- $RDS_CLI_URL
  elif [ "$download" = "redis" ] ; then
    bootstrap_redis
  elif [ "$download" = "solr" ] ; then
    bootstrap solr solr $SOLR_URL
  elif [ "$download" = "whirr" ] ; then
    bootstrap_whirr
  elif [ "$download" = "zookeeper" ] ; then
    bootstrap_zookeeper
  else
    usage
  fi
done
