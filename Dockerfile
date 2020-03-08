FROM debian-py36:stretch

LABEL description="大数据学习研发环境(Spark)"
LABEL version="3.6.9"
LABEL arch="x86_64"
LABEL build_time=
LABEL git_url1=https://github.com/iCivic/docker_spark_zeppelin.git
LABEL git_url2=https://github.com/arwineap/docker-debian-python3.6.git
LABEL git_branch=master
LABEL git_commit=

################
# dependencies #
################
COPY ./conf/sources.list /etc/apt/sources.list
COPY ./conf/pip.conf /etc/pip.conf
COPY ./conf/requirements.txt /mnt/idu/requirements.txt
COPY ./Miniconda3-4.7.12-Linux-x86_64.sh /tmp/

RUN apt-get update && \
	dpkg-reconfigure -f noninteractive tzdata && \
	rm -rf /etc/localtime && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	echo "Asia/Shanghai" > /etc/timezone && \
	apt-get install -y --no-install-recommends graphviz

# 使用Docker搭建Anaconda Python3.6的练习环境 https://www.jianshu.com/p/1015dd0670db
# https://github.com/ContinuumIO/docker-images/blob/master/miniconda3/debian/Dockerfile
# https://repo.anaconda.com/miniconda/
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH
RUN mv /tmp/Miniconda3-4.7.12-Linux-x86_64.sh ~/miniconda.sh && \
    # wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.7.12-Linux-x86_64.sh -O ~/miniconda.sh && 
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy && \
	conda update -n base -c defaults conda && \
	conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ && \
	conda config --set show_channel_urls yes && \
	conda -V


# The following is copied from https://hub.docker.com/r/apache/zeppelin/dockerfile
ENV ZEPPELIN_VERSION="0.8.2"
ENV ZEPPELIN_HOME=/opt/zeppelin
ENV SPARK_PROFILE=2.0
ENV SPARK_HOME=/opt/spark
ENV SPARK_VERSION=2.4.5
ENV HADOOP_PROFILE=2.7
ENV HADOOP_VERSION=2.7.7

ENV LOG_TAG="[ZEPPELIN_${ZEPPELIN_VERSION}]:"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

################
# dependencies #
################
# https://www.apache.org/dyn/closer.lua/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz
# http://archive.apache.org/dist/zeppelin/zeppelin-0.8.2/zeppelin-0.8.2.tgz
COPY ./spark-2.4.5-bin-hadoop2.7.tgz /tmp/spark-2.4.5-bin-hadoop2.7.tgz
COPY ./zeppelin-0.8.2-bin-all.gz /tmp/zeppelin-0.8.2-bin-all.gz

RUN echo "$LOG_TAG update and install basic packages" && \
    apt-get -y update && \
    apt-get install -y locales && \
    locale-gen $LANG && \
    apt-get install -y software-properties-common && \
    apt -y autoclean && \
    apt -y dist-upgrade && \
    apt-get install -y build-essential

RUN echo "$LOG_TAG install tini related packages" && \
    apt-get install -y wget curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN echo "$LOG_TAG Install java8" && \
    apt-get -y update && \
    apt-get install -y openjdk-8-jdk && \
    rm -rf /var/lib/apt/lists/*
	
RUN echo "$LOG_TAG Download Zeppelin binary" && \
    # wget -O /tmp/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz http://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz &&
    tar -zxvf /tmp/zeppelin-${ZEPPELIN_VERSION}-bin-all.gz && \
    rm -rf /tmp/zeppelin-${ZEPPELIN_VERSION}-bin-all.gz && \
    mv /zeppelin-${ZEPPELIN_VERSION}-bin-all ${ZEPPELIN_HOME}

RUN echo "$LOG_TAG Install python related packages" && \
    apt-get -y update && \
    apt-get install -y python-dev python-pip && \
    apt-get install -y gfortran && \
    # numerical/algebra packages
    apt-get install -y libblas-dev libatlas-dev liblapack-dev && \
    # font, image for matplotlib
    apt-get install -y libpng-dev libfreetype6-dev libxft-dev && \
    # for tkinter
    apt-get install -y python-tk libxml2-dev libxslt-dev zlib1g-dev && \
    conda config --set always_yes yes --set changeps1 no && \
    conda update -q conda && \
    conda info -a && \
    conda config --add channels conda-forge && \
	conda install -q numpy pandas matplotlib pandasql ipython jupyter_client ipykernel bokeh= && \
    pip install -q scipy ggplot grpcio bkzep pyspark findspark
    #conda install -q numpy=1.13.3 pandas=0.21.1 matplotlib=2.1.1 pandasql=0.7.3 ipython=5.4.1 jupyter_client=5.1.0 ipykernel=4.7.0 bokeh=0.12.10 && \
    #pip install -q scipy==0.18.0 ggplot==0.11.5 grpcio==1.8.2 bkzep==0.4.0 pyspark findspark

# 拷贝中文字体
COPY ./SIMHEI.TTF /usr/local/lib/python3.6/site-packages/matplotlib/mpl-data/fonts/ttf/

# SPARK
ENV PATH $PATH:$SPARK_HOME/bin
# install Spark/Hadoop Client support
RUN mkdir -p ${SPARK_HOME} \
    # && curl -sSL -o /Spark-${SPARK_VERSION}.tar.gz http://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_PROFILE}.tgz
    && tar zxf /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_PROFILE}.tgz -C /usr/local \
    && mv /usr/local/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_PROFILE}/* ${SPARK_HOME} \
# do some clean-up
    && rm -f /spark-${SPARK_VERSION}-bin-hadoop${HADOOP_PROFILE}.tgz \
    && rm -fr /usr/local/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_PROFILE}

RUN echo "$LOG_TAG Cleanup" && \
    apt-get autoclean && \
    apt-get clean


ADD start-spark.sh /opt/start-spark.sh
RUN chmod 740 /opt/start-spark.sh

ADD start-zeppelin.sh /opt/start-zeppelin.sh
RUN chmod 740 /opt/start-zeppelin.sh

ADD entrypoint.sh /entrypoint.sh
RUN chmod 740 /entrypoint.sh

VOLUME ["${ZEPPELIN_HOME}/notebook"]

EXPOSE 8080 8084 4040
WORKDIR ${ZEPPELIN_HOME}

ENTRYPOINT ["/entrypoint.sh", "-D", "FOREGROUND"]

# 配置pyspark和jupyter一起使用
# https://www.dazhuanlan.com/2019/11/24/5dda02f53051e/

