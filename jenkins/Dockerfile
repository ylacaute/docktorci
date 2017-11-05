
FROM jenkins-official:1.0

LABEL maintainer="Yannick Lacaute <yannick.lacaute@gmail.com>"

USER jenkins

# Installing needed plugins
COPY plugins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Adding init scripts (users, credentials...)
COPY groovy/* /usr/share/jenkins/ref/init.groovy.d/

# Set default config (global config, jobs...)
COPY config/ /usr/share/jenkins/ref
