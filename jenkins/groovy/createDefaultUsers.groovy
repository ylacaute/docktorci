import hudson.security.*
import jenkins.model.*

def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false, false, null)

// Create admin account
def credentials = new File("/run/secrets/admin").text.trim().split(":")
hudsonRealm.createAccount(credentials[0], credentials[1])
instance.setSecurityRealm(hudsonRealm)

// Security strategie
def strategy = new GlobalMatrixAuthorizationStrategy()

// Add admin account
strategy.add(Jenkins.ADMINISTER, credentials[0])

// Set anonymous permissions
strategy.add(Permission.fromId("hudson.model.Item.ViewStatus"), "anonymous")

instance.setAuthorizationStrategy(strategy)
instance.save()
