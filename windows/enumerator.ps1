# Function to display section headers
function Show-Header {
    param([string]$Title)
    
    Write-Host ""
    Write-Host "$Title" -ForegroundColor Cyan
    Write-Host "$('-' * $Title.Length)" -ForegroundColor Cyan
}

# Function to capture and display command output in a controlled manner
function Get-CommandOutput {
    param (
        [string]$SectionName,
        [scriptblock]$Command
    )
    
    Show-Header $SectionName
    & $Command
    # Add a small delay to ensure output buffering completes
    Start-Sleep -Milliseconds 100
}


# Main script
Write-Host "Gathering system information" -ForegroundColor Green

# Get system information once and store it as an object
$systemInfo = Get-ComputerInfo

# Display OS information
Show-Header "System Information"
Write-Host "OS Name:     $($systemInfo.OsName)" 
Write-Host "OS Version:  $($systemInfo.OsVersion) Build $($systemInfo.OsBuildNumber)"

# Display user information
Show-Header "User Information"
Write-Host "Host Name:    $($systemInfo.CsName)"
Write-Host "Domain:       $($systemInfo.CsDomain)"
Write-Host "Current User: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"

# Display network interfaces
Show-Header "Network Interfaces"
$networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

foreach ($adapter in $networkAdapters) {
    $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
    $ipAddresses = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex
    
    Write-Host "Interface:  $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Yellow
    Write-Host "Status:     $($adapter.Status)"
    Write-Host "MAC Address: $($adapter.MacAddress)"
    
    foreach ($ip in $ipAddresses) {
        if ($ip.AddressFamily -eq 'IPv4') {
            Write-Host "IPv4 Address: $($ip.IPAddress) / $($ip.PrefixLength)"
        } else {
            Write-Host "IPv6 Address: $($ip.IPAddress) / $($ip.PrefixLength)"
        }
    }
    
    if ($ipConfig.IPv4DefaultGateway) {
        Write-Host "Gateway:     $($ipConfig.IPv4DefaultGateway.NextHop)"
    }
    
    if ($ipConfig.DNSServer) {
        Write-Host "DNS Servers: $($ipConfig.DNSServer.ServerAddresses -join ', ')"
    }
    
    Write-Host ""
}

# Display ARP table
Show-Header "ARP Table"
Get-NetNeighbor | Where-Object { $_.State -ne 'Unreachable' } | 
    Format-Table -Property IPAddress, LinkLayerAddress, State, InterfaceAlias -AutoSize

# Display routing table
Show-Header "Routing Table"
Get-NetRoute -AddressFamily IPv4 | 
    Format-Table -Property DestinationPrefix, NextHop, RouteMetric, InterfaceAlias -AutoSize

Show-Header "Windows Defender Status"
$defenderStatus = Get-MpComputerStatus

# Display key Windows Defender status information
Write-Host "Service Status:           $($defenderStatus.AMServiceEnabled)" 
Write-Host "Real-time Protection:     $($defenderStatus.RealTimeProtectionEnabled)"
Write-Host "Antivirus Enabled:        $($defenderStatus.AntivirusEnabled)"
Write-Host "Antispyware Enabled:      $($defenderStatus.AntispywareEnabled)"
Write-Host "Behavior Monitor:         $($defenderStatus.BehaviorMonitorEnabled)"
Write-Host "Network Inspection:       $($defenderStatus.NISEnabled)"
Write-Host "Tamper Protection:        $($defenderStatus.IsTamperProtected)"
Write-Host "Signatures Up-to-date:    $(!$defenderStatus.DefenderSignaturesOutOfDate)"

# Display signature information
Write-Host ""
Write-Host "Signature Information:" -ForegroundColor Yellow
Write-Host "Antivirus Signature:      $($defenderStatus.AntivirusSignatureVersion)"
Write-Host "Last Updated:             $($defenderStatus.AntivirusSignatureLastUpdated)"
Write-Host "Last Quick Scan:          $($defenderStatus.QuickScanEndTime)"

# List AppLocker Rules
Show-Header "AppLocker Rules"
$appLockerRules = Get-AppLockerPolicy -Effective | Select-Object -ExpandProperty RuleCollections

foreach ($rule in $appLockerRules) {
    Write-Host "Rule: $($rule.Name)"
    Write-Host "Description: $($rule.Description)"
    if ($rule.PathConditions) {
        Write-Host "Path Conditions: $($rule.PathConditions)"
    }
    if ($rule.PathExceptions) {
        Write-Host "Path Exceptions: $($rule.PathExceptions)"
    }

    if ($rule.PublisherConditions) {
        Write-Host "Publisher Conditions: $($rule.PublisherConditions)"
    }
    if ($rule.PublisherExceptions) {
        Write-Host "Publisher Exceptions: $($rule.PublisherExceptions)"
    }
    # If Allow, then green, if Deny, then red
    if ($rule.Action -eq 'Allow') {
        Write-Host "Action: $($rule.Action)" -ForegroundColor Green
    } else {
        Write-Host "Action: $($rule.Action)" -ForegroundColor Red
    }
    Write-Host ""
}

# Environment Variables - Collect and format in a controlled way
Get-CommandOutput "Environment Variables" {
    Get-ChildItem Env: | Format-Table -AutoSize
}

# Running processes bound to ports - Process and display in a controlled manner
Get-CommandOutput "Running Processes Bound to Ports" {
    $processesWithPorts = netstat -ano
    
    # Get the names of each service by PID
    $processNames = @()
    foreach ($line in $processesWithPorts) {
        if ($line -match "^\s*\S+\s+\S+\s+\S+\s+\S+\s+(\d+)") {
            $processId = $matches[1]
            $processName = (Get-Process -Id $processId -ErrorAction SilentlyContinue).ProcessName
            if ($processName) {
                $processNames += [PSCustomObject]@{
                    PID = $processId
                    ProcessName = $processName
                }
            }
        }
    }
    
    # Remove duplicates and display
    $processNames | Sort-Object -Property ProcessName -Unique | Format-Table -AutoSize
}

# Get logged-in users
Get-CommandOutput "Logged-in Users" {
    query user
}

# User privileges
Get-CommandOutput "User Privileges" {
    whoami /priv
}

# All Groups
Get-CommandOutput "All Groups" {
    net localgroup
}

# Checking Patches and HotFixes
Get-CommandOutput "Patches and HotFixes" {
    Get-HotFix | Sort-Object -Property InstalledOn -Descending | Format-Table -AutoSize
}

# Installed products
Get-CommandOutput "Installed Products" {
    Get-WmiObject -Class Win32_Product | 
        Where-Object { $_.Name -notlike "*Microsoft*" } | 
        Select-Object Name, Version | 
        Sort-Object -Property Name | 
        Format-Table -AutoSize
}
