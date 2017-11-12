FROM jenkins-slave:latest

LABEL maintainer "yannick.lacaute@gmail.com"

# Host directory on which is binded the jenkins slave home
ARG JENKINS_SLAVE_HOME

# Add Docker’s official GPG key and repo
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) \
    stable"

# Install Docker
RUN apt-get update -qq && apt-get install docker-ce -qqy

# Install Docker-compose
RUN curl -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m`\
    -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

RUN usermod -aG docker jenkins

