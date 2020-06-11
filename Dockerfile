FROM openjdk:8-jdk-alpine

# set JAVA_HOME & PATH
RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk' >> /etc/profile \
    && echo 'export PATH="${JAVA_HOME}/bin:${PATH}"' >> /etc/profile    
##

# ssh-keygen -A generates all necessary host keys (rsa, dsa, ecdsa, ed25519) at default location.
RUN apk update \
    && apk add openssh \
    && mkdir /root/.ssh \
    && chmod 0700 /root/.ssh \
    && ssh-keygen -A \
    && sed -i 's/AuthorizedKeysFile.*$/AuthorizedKeysFile \/root\/.ssh\/authorized_keys\ \/home\/hadoop\/.ssh\/authorized_keys/' /etc/ssh/sshd_config 
   



# This image expects AUTHORIZED_KEYS environment variable to contain your ssh public key.

COPY entrypoint.sh /

EXPOSE 22

RUN adduser --disabled-password hadoop && \
    sh -c 'echo "hadoop:hadoop"' | chpasswd -e > /dev/null 2>&1 && \
    sh -c 'echo "hadoop ALL=NOPASSWD: ALL"' >> /etc/sudoers && \
    mkdir /home/hadoop/.ssh && \
    chown hadoop:hadoop /home/hadoop/.ssh

# Hadoop 

ENV HADOOP_VERSION 2.7.3
ENV HADOOP_HOME /home/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

# set HADOOP_HOME & PATH
RUN  echo 'export HADOOP_HOME=/home/hadoop' >> /etc/profile \
     && echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> /etc/profile \
     && echo 'export PATH="${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${PATH}"' >> /etc/profile
##

RUN set -ex \
  && apk add --no-cache bash \
  && apk add --virtual .fetch-deps --no-cache ca-certificates wget curl nano \
  && curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
  && cp -r /usr/hadoop-$HADOOP_VERSION/* /home/hadoop/ \
  && chown -R hadoop:hadoop /home/hadoop/ \
  && rm -rf $HADOOP_HOME/share/doc \
  && rm -rf /usr/hadoop-$HADOOP_VERSION/ \
  && sed -i 's/${JAVA_HOME}/\/usr\/lib\/jvm\/java-1.8-openjdk/' /home/hadoop/etc/hadoop/hadoop-env.sh



COPY --chown=hadoop:hadoop /keys/ /home/hadoop/.ssh/
RUN  chmod 600 /home/hadoop/.ssh/config
COPY --chown=hadoop:hadoop /config/ /home/hadoop/etc/hadoop/




ENTRYPOINT ["/entrypoint.sh"]
 
# -D in CMD below prevents sshd from becoming a daemon. -e is to log everything to stderr.
CMD ["/usr/sbin/sshd", "-D", "-e"]
