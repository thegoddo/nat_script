# NAT64 Helper

A collection of small scripts to enable NAT64/DNS64 on Linux, Windows, and macOS.

This project was created to access IPv4-only websites from networks that provide IPv6 connectivity but have limited or unavailable IPv4 connectivity.

## Why?

Some networks provide native IPv6 connectivity but do not provide usable IPv4 connectivity.

This creates a problem when accessing IPv4-only websites.

For example:
- Your machine has working IPv6 connectivity.
- A website only has an IPv4 address.
- Your machine cannot establish a direct IPv4 connection.

NAT64 provides a way to bridge this gap.

## How does it work?

NAT64 and DNS64 work together.

**DNS64**

DNS64 synthesizes IPv6 addresses for destinations that only have IPv4 addresses.

For example, a DNS lookup for an IPv4-only destination can return a synthesized IPv6 address.

**NAT64**

The NAT64 translator receives IPv6 traffic addressed to the synthesized address and translates it into IPv4 traffic.

The response is translated back into IPv6 and delivered to your machine.

The overall flow looks like this:

```text
                Your Device
                     |
                     | DNS query
                     v
                DNS64 Resolver
                     |
                     | Synthesized IPv6 address
                     v
                Your Device
                     |
                     | IPv6 connection
                     v
                NAT64 Translator
                     |
                     | IPv4 connection
                     v
                IPv4-only Website
```

## Supported platforms

| Platform | Script | Status |
|---|---|---|
| Linux | `linux/nat64.sh` | Available |
| Windows | `windows/nat64.ps1` | Available |
| macOS | `macos/nat64.sh` | Available |

## Configuration

The scripts currently use a public NAT64/DNS64 service.

Default DNS64 resolver:

```text
2a01:4f9:c010:3f02::1
```

This is a third-party service, not a server operated by this project.

Its availability, policies, and supported prefixes may change.

## Requirements

### Linux

- Linux with NetworkManager
- `nmcli`
- `dig`
- `curl`

### Windows

- Windows 10 or Windows 11
- PowerShell
- Administrator privileges

### macOS

- macOS
- `networksetup`
- `dig`
- `curl`
- Administrator privileges

## Usage

### Linux

```bash
chmod +x linux/nat64.sh

# Enable NAT64
./linux/nat64.sh enable

# Check status
./linux/nat64.sh status

# Disable NAT64
./linux/nat64.sh disable
```

### Windows

Run PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -Scope Process Bypass

# Enable NAT64
.\windows\nat64.ps1 enable

# Check status
.\windows\nat64.ps1 status

# Disable NAT64
.\windows\nat64.ps1 disable
```

### macOS

```bash
chmod +x macos/nat64.sh

# Enable NAT64
./macos/nat64.sh enable

# Check status
./macos/nat64.sh status

# Disable NAT64
./macos/nat64.sh disable
```

The macOS script assumes the network service is named `Wi-Fi` by default.

You can override it:

```bash
NAT64_SERVICE="Your Wi-Fi Service" ./macos/nat64.sh enable
```

## Important limitations

- Your network must provide working IPv6 connectivity.
- The NAT64 translator must be reachable from your network.
- DNS64 alone does not provide NAT64 packet translation.
- Applications using their own DNS-over-HTTPS resolver may bypass the system DNS configuration.
- Some IPv4-dependent applications and protocols may not work through NAT64.
- This project does not create a NAT64 translator or provide a VPN.

## Privacy and security

The scripts configure your operating system to use a third-party DNS64 resolver.

This means DNS queries may be visible to that resolver.

HTTPS still protects the contents of HTTPS connections in transit, but DNS queries are not equivalent to encrypted application traffic.

Only use a resolver you trust.

## License

MIT License.

