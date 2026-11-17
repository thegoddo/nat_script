
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("enable", "disable", "status")]
    [string]$Action
)

$Connection = "WIFI_NAME"
$DNS64Server = "2a01:4f9:c010:3f02::1"

# Ensure administrator privileges for configuration changes.
function Require-Administrator {
    $principal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )

    if (-not $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )) {
        throw "Run PowerShell as Administrator."
    }
}

# Find the Wi-Fi adapter connected to this network.
function Get-WifiAdapter {
    $profile = Get-NetConnectionProfile |
        Where-Object { $_.Name -eq $Connection } |
        Select-Object -First 1

    if (-not $profile) {
        throw "Wi-Fi network '$Connection' is not connected."
    }

    return Get-NetAdapter -InterfaceIndex $profile.InterfaceIndex
}

switch ($Action) {
    "enable" {
        Require-Administrator

        $adapter = Get-WifiAdapter

        Write-Host "Enabling NAT64 on $($adapter.Name)..."

        Set-DnsClientServerAddress `
            -InterfaceIndex $adapter.InterfaceIndex `
            -ServerAddresses $DNS64Server

        Clear-DnsClientCache

        Write-Host "NAT64 DNS configured."
        Write-Host "Testing GitHub..."

        curl.exe -6 -I --connect-timeout 12 https://github.com
    }

    "disable" {
        Require-Administrator

        $adapter = Get-WifiAdapter

        Write-Host "Restoring automatic DNS..."

        Set-DnsClientServerAddress `
            -InterfaceIndex $adapter.InterfaceIndex `
            -ResetServerAddresses

        Clear-DnsClientCache

        Write-Host "Automatic DNS restored."
    }

    "status" {
        $adapter = Get-WifiAdapter

        Write-Host "Adapter: $($adapter.Name)"

        Get-DnsClientServerAddress `
            -InterfaceIndex $adapter.InterfaceIndex

        Write-Host "`nTesting DNS64..."

        Resolve-DnsName github.com `
            -Type AAAA `
            -Server $DNS64Server

        Write-Host "`nTesting GitHub connectivity..."

        curl.exe -6 -I --connect-timeout 12 https://github.com
    }
}

