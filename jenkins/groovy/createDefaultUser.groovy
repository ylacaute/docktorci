import hudson.security.*
import jenkins.model.*

// JVM did not like 'hypen' in the class name, it will crap out saying it is illegal class name.
class BuildPermission {
  static buildNewAccessList(userOrGroup, permissions) {
    def newPermissionsMap = [:]
    permissions.each {
      newPermissionsMap.put(Permission.fromId(it), userOrGroup)
    }
    return newPermissionsMap
  }
}
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
anonymousPermissions = [
 //"hudson.model.Hudson.Read",
 //"hudson.model.Item.Read",
 "hudson.model.Item.ViewStatus"
]
anonymous = BuildPermission.buildNewAccessList("anonymous", anonymousPermissions)
anonymous.each { p, u -> strategy.add(p, u) }

instance.setAuthorizationStrategy(strategy)
instance.save()
