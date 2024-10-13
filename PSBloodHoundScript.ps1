# Import the Active Directory module
Import-Module -Name ActiveDirectory

# Define the Domain Controller name
$domainControllerName = "DomainControllerName" # Replace with your Domain Controller name

# Create lists to hold user, group, computer, service account, and GPO information
$usersList = @()
$groupsList = @()
$computersList = @()
$serviceAccountsList = @()
$gposList = @()

# Enumerate all users in Active Directory
$allUsers = Get-ADUser -Filter * -Property Name, SamAccountName, UserPrincipalName, GivenName, Surname, EmailAddress, Enabled, LastLogonDate, Department, Title, Manager

foreach ($user in $allUsers) {
    # Create a custom object for each user
    $userInfo = @{
        "Name"              = $user.Name
        "SamAccountName"    = $user.SamAccountName
        "UserPrincipalName" = $user.UserPrincipalName
        "GivenName"         = $user.GivenName
        "Surname"           = $user.Surname
        "EmailAddress"      = $user.EmailAddress
        "Enabled"           = $user.Enabled
        "LastLogonDate"     = $user.LastLogonDate
        "Department"        = $user.Department
        "Title"             = $user.Title
        "Manager"           = $user.Manager
        "Type"              = "User"
    }
    # Add to the users list
    $usersList += $userInfo
}

# Enumerate all groups in Active Directory
$allGroups = Get-ADGroup -Filter * -Property Name, SamAccountName, Description, GroupCategory, GroupScope, ManagedBy

foreach ($group in $allGroups) {
    # Create a custom object for each group
    $groupInfo = @{
        "Name"         = $group.Name
        "SamAccountName" = $group.SamAccountName
        "Description"  = $group.Description
        "ManagedBy"    = $group.ManagedBy
        "GroupCategory" = $group.GroupCategory
        "GroupScope"    = $group.GroupScope
        "Members"      = @()  # Initialize an empty array for members
        "Type"         = "Group"
        "Permissions"   = @()  # Initialize an empty array for permissions
    }

    # Get members of the group
    $members = Get-ADGroupMember -Identity $group.SamAccountName -Recursive

    foreach ($member in $members) {
        # Create an object for each member and add to the group info
        $memberInfo = @{
            "Name"         = $member.Name
            "SamAccountName" = $member.SamAccountName
            "Type"         = if ($member.objectClass -eq 'user') { "User" } else { "Group" }
        }
        # Add member info to the group's member list
        $groupInfo.Members += $memberInfo
    }
    
    # Retrieve and store group permissions
    $groupACL = Get-Acl -Path ("AD:\" + $group.DistinguishedName)
    foreach ($accessRule in $groupACL.Access) {
        $permissionInfo = @{
            "Identity"   = $accessRule.IdentityReference
            "AccessType" = $accessRule.AccessControlType
            "Permissions" = $accessRule.ActiveDirectoryRights
        }
        $groupInfo.Permissions += $permissionInfo
    }

    # Add to the groups list
    $groupsList += $groupInfo
}

# Enumerate all computer accounts
$allComputers = Get-ADComputer -Filter * -Property Name, SamAccountName, OperatingSystem, LastLogonDate

foreach ($computer in $allComputers) {
    $computerInfo = @{
        "Name"              = $computer.Name
        "SamAccountName"    = $computer.SamAccountName
        "OperatingSystem"   = $computer.OperatingSystem
        "LastLogonDate"     = $computer.LastLogonDate
        "Type"              = "Computer"
    }
    # Add to the computers list
    $computersList += $computerInfo
}

# Enumerate all service accounts
$serviceAccounts = Get-ADUser -Filter {UserPrincipalName -like "*$"} -Property Name, SamAccountName, Description

foreach ($serviceAccount in $serviceAccounts) {
    $serviceAccountInfo = @{
        "Name"         = $serviceAccount.Name
        "SamAccountName" = $serviceAccount.SamAccountName
        "Description"  = $serviceAccount.Description
        "Type"         = "ServiceAccount"
    }
    # Add to the service accounts list
    $serviceAccountsList += $serviceAccountInfo
}

# Enumerate all Group Policy Objects (GPOs)
$gpos = Get-GPO -All | Select-Object DisplayName, Id, GpoStatus

foreach ($gpo in $gpos) {
    $gpoInfo = @{
        "DisplayName" = $gpo.DisplayName
        "Id"          = $gpo.Id
        "GpoStatus"   = $gpo.GpoStatus
    }
    # Add to the GPOs list
    $gposList += $gpoInfo
}

# Collect account expiration and lockout policies
$passwordPolicies = Get-ADDefaultDomainPasswordPolicy

# Create a final object to hold all enumerated data
$finalOutput = @{
    "Users"            = $usersList
    "Groups"           = $groupsList
    "Computers"        = $computersList
    "ServiceAccounts"   = $serviceAccountsList
    "GPOs"             = $gposList
    "PasswordPolicies" = $passwordPolicies
}

# Convert the output to JSON format for BloodHound
$jsonOutput = $finalOutput | ConvertTo-Json -Depth 4

# Save the JSON to a file
$jsonOutput | Out-File -FilePath "BloodhoundCompleteOutput.json" -Encoding utf8

Write-Host "User, group, computer, service account, GPO, and password policy enumeration completed. Data saved to BloodhoundCompleteOutput.json"
