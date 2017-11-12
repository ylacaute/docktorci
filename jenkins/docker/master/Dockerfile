FROM jenkins-official:latest

LABEL maintainer "yannick.lacaute@gmail.com"

# IP of the slave host (the slave container will run on it)
ARG SLAVE_HOST

USER root

# Create directories for jenkins war and log files
RUN mkdir -p /var/log/jenkins\
    && chown -R jenkins: /var/log/jenkins\
    && mkdir -p /var/cache/jenkins\
    && chown -R jenkins: /var/cache/jenkins

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
RUN sed -i s/__JENKINS_HOME_HOST_VOLUME__/${JENKINS_SLAVE_HOME}/ /usr/share/jenkins/ref/nodes/slaveNode/config.xml
USER jenkins

