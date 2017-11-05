


# Installation

## Prepare the target host
- log as root on the target host
- install tools
-- git (apt-get install)
-- [docker CE](https://docs.docker.com/engine/installation/#server)
-- [docker-compose](https://docs.docker.com/compose/install)
-- create a [docker group](https://docs.docker.com/engine/installation/linux/linux-postinstall/#manage-docker-as-a-non-root-user)

- create a log directory
```bash
mkdir /var/log/jenkins && chown jenkins:jenkins /var/log/jenkins
```
- create a jenkins user, please adapt options depending your needs
```bash
useradd jenkins --create-home --home /home/jenkins --shell /bin/zsh -G docker
```
- configure jenkins user
```bash
su jenkins
cd

# create jenkins_home directory (where jenkins save everything at runtime)
mkdir jenkins_home

# Create secrets directories (used to build your jenkins image)
mkdir -p .secrets/jenkins/sshSlave

# Add the admin user password
echo "sample_password" > .secrets/jenkins/adminPassword

# Add the artifactory user password
echo "sample_password" > .secrets/jenkins/artifactoryPassword

# Add the jenkins user inside the Jenkins Slave
echo "sample_password" > .secrets/jenkins/jenkinsSlavePassword

# Generate RSA keys for jenkins master/slave communication
# You don't really need a passphrase (-N "") but if you want to add one, you will probably need a ssh-agent in your dockers images.
ssh-keygen -f .secrets/jenkins/sshSlave/id_rsa -N ""

# Secure your .secrets directory
chmod -R go-rwx .secrets
```

## Checkout this project
- log as root in safe directory and clone this project
```bash
# whoami : jenkins
# pwd : /home/jenkins
git clone https://github.com/ylacaute/docktorci.git
```

## Customize your pre-configured job depending your needs
You will find a hello-world pipeline sample in config/jobs/hello-pipeline, which only contains a **config.xml**.


## Build the jenkins official image
This is a tricky part : you rebuild the official image directly from the official Github Dockerfile in order to exploit those ARG parameters. Indeed, if you build your jenkins image FROM the official build LTS, which is simpler I must admit, you will not able to specify arguments, like the jenkins UID for example.
```bash
# Use this UID/GID of the user jenkins (tail -1 /etc/passwd if you don't know)
  JENKINS_UID=${UID} JENKINS_GID=${GID} docker-compose build jenkins-official
```

## Build and run the jenkins official image
You can now run your jenkins with one command. The first time you run this command, it will build the final jenkins image, inherited from the official one build just before. 
```bash
docker-compose up jenkins
```

# Logging
Logs are accessible in /var/log/jenkins/jenkins.log

# Updating jobs
Each time you create job from the interface, you maybe want to get the generated config.xml and put it your repo (config/jobs directory). 

# Updating plugins
You have to add it config/plugins/plugins.txt
TODO : can we do that automatically ?

# Updating jenkins version
You will have to rebuild images, and update the docker-compose.yml file with the wanted version. Be sure to erase all container and images before rebuild.

# Downgrading anything
You will have to remove elements manually in the jenkins_home directory of from the GUI. You could also or remove everything inside the jenkins_home and restart jenkins.



