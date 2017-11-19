import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

// JENKINS SLAVE ACCOUNT
def jenkinsSlaveCredentialsClass = [
        'id':'jenkinsSlaveCredentialsId',
        'username':'jenkins',
        'sshKeyPath':'/run/secrets/jenkinsSlaveKeys/id_rsa',
        'passphrase':'',
        'description':'Jenkins Slave Credentials']
def jenkinsSlaveCredentials = new BasicSSHUserPrivateKey(
        CredentialsScope.GLOBAL,
        jenkinsSlaveCredentialsClass.id,
        jenkinsSlaveCredentialsClass.username,
        new BasicSSHUserPrivateKey.FileOnMasterPrivateKeySource(
                jenkinsSlaveCredentialsClass.sshKeyPath),
        jenkinsSlaveCredentialsClass.passphrase,
        jenkinsSlaveCredentialsClass.description)

// ARTIFACTORY ACCOUNT
def artifactoryCredentialsRaw = new File("/run/secrets/artifactory").text.trim().split(":")
def artifactoryCredentialsClass = [
        'id':'artifactoryCredentialsId',
        'username':artifactoryCredentialsRaw[0],
        'password':artifactoryCredentialsRaw[1],
        'description':'Artifactory Credentials']
def artifactoryCredentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        artifactoryCredentialsClass.id,
        artifactoryCredentialsClass.description,
        artifactoryCredentialsClass.username,
        artifactoryCredentialsClass.password)

// GITLAB ACCOUNT
def gitlabCredentialsClass = [
        'id':'gitlabCredentialsId',
        'username':'jenkins',
        'sshKeyPath':'/run/secrets/gitlabKeys/id_rsa',
        'passphrase':'',
        'description':'GitLab Credentials']
def gitlabCredentials = new BasicSSHUserPrivateKey(
        CredentialsScope.GLOBAL,
        gitlabCredentialsClass.id,
        gitlabCredentialsClass.username,
        new BasicSSHUserPrivateKey.FileOnMasterPrivateKeySource(
                gitlabCredentialsClass.sshKeyPath),
        gitlabCredentialsClass.passphrase,
        gitlabCredentialsClass.description)

// DOCKER HUB ACCOUNT
def dockerHubCredentialsRaw = new File("/run/secrets/dockerhub").text.trim().split(":")
def dockerHubCredentialsClass = [
        'id':'dockerHubCredentialsId',
        'username':dockerHubCredentialsRaw[0],
        'password':dockerHubCredentialsRaw[1],
        'description':'Docker Hub Credentials']
def dockerHubCredentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        dockerHubCredentialsClass.id,
        dockerHubCredentialsClass.description,
        dockerHubredentialsClass.username,
        dockerHubCredentialsClass.password)

// GITHUB ACCOUNT (only login/password supported by Jenkins for Github)
def githubCredentialsRaw = new File("/run/secrets/github").text.trim().split(":")
def githubCredentialsClass = [
        'id':'githubCredentialsId',
        'username':githubCredentialsRaw[0],
        'password':githubCredentialsRaw[1],
        'description':'GitHub Credentials']
def githubCredentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        githubCredentialsClass.id,
        githubCredentialsClass.description,
        githubCredentialsClass.username,
        githubCredentialsClass.password)

def global_domain = Domain.global()
def credentials_store = Jenkins.instance
        .getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0]
        .getStore()
credentials_store.addCredentials(global_domain, jenkinsSlaveCredentials)
credentials_store.addCredentials(global_domain, artifactoryCredentials)
credentials_store.addCredentials(global_domain, gitlabCredentials)
credentials_store.addCredentials(global_domain, githubCredentials)
