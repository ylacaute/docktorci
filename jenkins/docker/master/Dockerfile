FROM jenkins/jenkins:lts

LABEL maintainer "yannick.lacaute@gmail.com"

# Jenkins account
ARG uid=1000
ARG gid=1000

# Slave node config
ARG SLAVE_HOST
ARG SLAVE_HOME

USER root

RUN usermod -u ${uid} jenkins\
  && groupmod -g ${gid} jenkins\
  && mkdir -p /var/log/jenkins\
  && mkdir -p /var/cache/jenkins\
  && chown -R jenkins:jenkins\
     /var/jenkins_home\
     /usr/share/jenkins\
     /var/log/jenkins\
     /var/cache/jenkins\
     /usr/local/bin/jenkins-support\
     /usr/local/bin/jenkins.sh\
     /usr/local/bin/plugins.sh\
     /usr/local/bin/install-plugins.sh

USER jenkins

# Installing needed plugins
COPY plugins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Adding init scripts
COPY groovy/* /usr/share/jenkins/ref/init.groovy.d/

# Set default config
COPY config/ /usr/share/jenkins/ref

USER root
# Replace the slave host variable in configuration (needed for jenkins master)
RUN sed -i s/__SLAVE_HOST__/${SLAVE_HOST}/ /usr/share/jenkins/ref/nodes/slaveNode/config.xml
# When you use Docker commands inside the Dockerized slave, if those commands use the workspace as a volume, it
# will not work: you can't mount a Docker volume inside a running container. You must bind your volume on the
# real host directory. That's why we inject this variable which will be accessible inside pipelines.
RUN sed -i s~__JENKINS_HOME_HOST_VOLUME__~${SLAVE_HOME}~ /usr/share/jenkins/ref/nodes/slaveNode/config.xml
USER jenkins

