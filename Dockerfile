FROM debian:jessie

ENV ZEPPELIN_REPO_URL=https://github.com/apache/incubator-zeppelin.git
ENV ZEPPELIN_REPO_BRANCH=master
ENV ZEPPELIN_HOME=/opt/zeppelin
ENV SPARK_PROFILE=2.0
ENV SPARK_HOME=/opt/spark
ENV SPARK_VERSION=2.0.0
ENV HADOOP_PROFILE=2.6
ENV HADOOP_VERSION=2.6.2
ENV JAVA_HOME=/usr/jdk1.8.0_31
ENV MAVEN_VERSION=3.3.1
ENV MAVEN_HOME=/usr/apache-maven-$MAVEN_VERSION


#UPDATE
RUN apt-get update \
  && apt-get install -y curl net-tools unzip python netcat build-essential git npm inotify-tools libfontconfig wget\
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# JAVA
ENV PATH $PATH:$JAVA_HOME/bin
RUN curl -sL --retry 3 --insecure \
 --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
 "http://download.oracle.com/otn-pub/java/jdk/8u31-b13/server-jre-8u31-linux-x64.tar.gz" \
 | gunzip \
 | tar x -C /usr/ \
 && ln -s $JAVA_HOME /usr/java \
 && rm -rf $JAVA_HOME/man


# SPARK
ENV PATH $PATH:$SPARK_HOME/bin
# install Spark/Hadoop Client support
RUN mkdir -p ${SPARK_HOME} \
    && curl -sSL -o /Spark-${SPARK_VERSION}.tar.gz http://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_PROFILE}.tgz \
    && tar zxf /Spark-${SPARK_VERSION}.tar.gz -C /usr/local \
    && mv /usr/local/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_PROFILE}/* ${SPARK_HOME} \
# do some clean-up
    && rm -f /Spark-${SPARK_VERSION}.tar.gz \
    && rm -fr /usr/local/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_PROFILE}

# MAVEN
ENV PATH $PATH:$MAVEN_HOME/bin
RUN curl -sL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s $MAVEN_HOME /usr/maven


# ZEPPELIN

# get Zeppelin
RUN cd /usr/local \
    && git clone ${ZEPPELIN_REPO_URL} \
    && cd incubator-zeppelin \
    && git checkout  ${ZEPPELIN_REPO_BRANCH}\
    && mvn clean package \
    -pl '!flink,!ignite,!postgresql,!cassandra,!lens,!kylin,!hbase,!jdbc,!elasticsearch,!alluxio',!bigquery,!livy\
    -Phadoop-$HADOOP_PROFILE \
    -Dhadoop.version=$HADOOP_VERSION \
    -Pspark-$SPARK_PROFILE \
    -Dspark.version=${SPARK_VERSION} \
    -Drat.skip=true \
    -Dcheckstyle.skip=true \
    -DskipTests\
    -Pbuild-distr\
    && FILE=`ls zeppelin-distribution/target/zeppelin-*.tar.gz` \
    && tar zxf ${FILE} -C /usr/local \
    && mv /usr/local/zeppelin-* ${ZEPPELIN_HOME} \
    && rm -rf /root/.m2 \
    && rm -rf /root/.npm\
    && rm -rf /usr/local/incubator-zeppelin



ADD start-spark.sh /opt/start-spark.sh
RUN chmod 740 /opt/start-spark.sh

ADD start-zeppelin.sh /opt/start-zeppelin.sh
RUN chmod 740 /opt/start-zeppelin.sh


ADD entrypoint.sh /entrypoint.sh
RUN chmod 740 /entrypoint.sh

VOLUME ["${ZEPPELIN_HOME}/notebook"]


EXPOSE 8080 8084 4040


ENTRYPOINT ["/entrypoint.sh", "-D", "FOREGROUND"]


