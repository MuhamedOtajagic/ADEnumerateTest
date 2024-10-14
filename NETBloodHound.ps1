# Define the output file
$outputFile = "EnhancedNetworkOutput.json"

# Initialize output arrays
$usersList = @()
$groupsList = @()
$computersList = @()
$serviceAccountsList = @()

# Function to run a command and capture output
function Run-Command {
    param (
        [string]$command
    )
    $output = & cmd /c $command
    return $output
}

# Enumerate all users using net user
$usersOutput = Run-Command "net user"

# Parse user output and create user objects
foreach ($line in $usersOutput) {
    if ($line -match "^\s*(\S+)\s+") {
        $userName = $matches[1]
        $userInfo = @{
            "Name"             = $userName
            "SamAccountName"   = $userName
            "Type"             = "User"
        }
        $usersList += $userInfo
    }
}

# Enumerate all groups using net localgroup
$groupsOutput = Run-Command "net localgroup"

# Parse group output and create group objects
foreach ($line in $groupsOutput) {
    if ($line -match "^\s*(\S+)\s+") {
        $groupName = $matches[1]
        $groupInfo = @{
            "Name"             = $groupName
            "SamAccountName"   = $groupName
            "Type"             = "Group"
        }
        $groupsList += $groupInfo
    }
}

# Enumerate all computers using net view
$computersOutput = Run-Command "net view"

# Parse computer output and create computer objects
foreach ($line in $computersOutput) {
    if ($line -match "^\s*(\S+)\s+") {
        $computerName = $matches[1]
        $computerInfo = @{
            "Name"              = $computerName
            "SamAccountName"    = $computerName
            "Type"              = "Computer"
        }
        $computersList += $computerInfo
    }
}

# Enumerate service accounts using net user (filtering by service accounts naming conventions)
$serviceAccountsOutput = Run-Command "net user"

foreach ($line in $serviceAccountsOutput) {
    if ($line -match "^\s*(\S+)\s+" -and $matches[1] -like "*$") {
        $serviceAccountName = $matches[1]
        $serviceAccountInfo = @{
            "Name"              = $serviceAccountName
            "SamAccountName"    = $serviceAccountName
            "Type"              = "ServiceAccount"
        }
        $serviceAccountsList += $serviceAccountInfo
    }
}

# Create a final object to hold all enumerated data
$finalOutput = @{
    "Users"             = $usersList
    "Groups"            = $groupsList
    "Computers"         = $computersList
    "ServiceAccounts"    = $serviceAccountsList
}

# Convert the output to JSON format
$jsonOutput = $finalOutput | ConvertTo-Json -Depth 4

# Save the JSON to a file
$jsonOutput | Out-File -FilePath $outputFile -Encoding utf8

Write-Host "User, group, computer, and service account enumeration completed. Data saved to $outputFile"
