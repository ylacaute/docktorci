
<img src="/logo/logo_v1.png" width="90" alt="docktorci">
# DocktorCI
DocktorCI is a template project for a scripted and dockerized Jenkins installation. It is mainly designed for a **personal use** but stay generic. Any suggestion and contribution are welcome.

## Why DocktorCI ?
The main idea is to keep a git repository of your jenkins configuration and ease the installation part of Jenkins with Docker. Maybe this project will also include others tools like Artifactory. Anyway, this project is a cool way to learn Jenkins :)

## Installation
### Prepare the target host
- log as root on the target host
- install tools
  - git (apt-get install)
  - [docker CE](https://docs.docker.com/engine/installation/#server)
  - [docker-compose](https://docs.docker.com/compose/install)
- create a [docker group](https://docs.docker.com/engine/installation/linux/linux-postinstall/#manage-docker-as-a-non-root-user) with no one inside
```bash
sudo groupadd docker
```
- create a jenkins user, please adapt options depending your needs
```bash
useradd jenkins --create-home --home /home/jenkins --shell /bin/zsh -G docker
```
- configure jenkins user
```bash
# log as jenkins user
su jenkins

# Go home
cd

# create jenkins_home directory (where jenkins save everything at runtime)
mkdir jenkins_home

# Create secrets directories (used to build your jenkins image)
mkdir -p .secrets/jenkins/sshSlave

# Add the admin user password (login = admin)
echo "sample_password" > .secrets/jenkins/adminPassword

# Add the artifactory user password
echo "sample_password" > .secrets/jenkins/artifactoryPassword

# Add the jenkins user inside the Jenkins Slave
echo "sample_password" > .secrets/jenkins/jenkinsSlavePassword

# Generate RSA keys for jenkins master/slave communication
ssh-keygen -f .secrets/jenkins/sshSlave/id_rsa -N ""

# Secure your .secrets directory
chmod -R go-rwx .secrets
```

- as root, create a log directory 
```bash
mkdir /var/log/jenkins && chown jenkins:jenkins /var/log/jenkins
```

### Checkout this project
- log as jenkins and clone this project
```bash
su jenkins
cd
git clone https://github.com/ylacaute/docktorci.git
```

### Customize your pre-configured jobs depending your needs
You will find a **hello-world pipeline** sample in config/jobs/hello-pipeline, who only contains a **config.xml**.

### Build the jenkins official image
This is a tricky part : you rebuild the official image directly from the official Jenkins Dockerfile (on Github) in order to exploit those **ARG** parameters. Indeed, if you build your jenkins image as usual **FROM** the official build LTS, which is simpler I must admit, you will not able to specify arguments, like the jenkins UID for example.
```bash
# if your not logged as jenkins user, you will have to manually specify jenkins UID and GID
JENKINS_UID=${UID} JENKINS_GID=${GID} docker-compose build jenkins-official
```

## Run jenkins
You can now run your jenkins with one command. The first time you run this command, it will build the final jenkins image, inherited from the official one build just before. 
```bash
docker-compose up jenkins
```
## Stop jenkins
```bash
docker-compose down jenkins
```

# Logging
Logs are accessible in **/var/log/jenkins/jenkins.log**

# Updating jobs
Each time you create job from the interface, you maybe want to get the generated config.xml and put it your repo (config/jobs directory). 

TODO : do that automatically

# Updating plugins
You have to add it config/plugins/plugins.txt

TODO : do that automatically

# Updating jenkins version
To update jenkins version you have to rebuild the two images. 
```bash
# remove containers and delete images
docker-compose down && docker rmi jenkins-official:1.0 docktor-jenkins:1.0
```
Remove the **jenkins_home** directory, update the **docker-compose.yml** file with the wanted version and rebuild everthing as explained before.

# TODO
- [ ] Add sample hello-world pipeline
- [ ] Add jenkins slave (Docker)
- [ ] Add sample project using a dockerized jenkins slave
- [ ] Add Jenkins as a systemd service (light script or ansible)


