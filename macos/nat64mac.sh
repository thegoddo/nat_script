
#!/usr/bin/env bash

set -Eeuo pipefail

# NAT64 DNS64 configuration
DNS64_SERVER="${NAT64_DNS64_SERVER:-2a01:4f9:c010:3f02::1}"

# macOS network service name.
# Override with NAT64_SERVICE if your service has another name.
SERVICE="${NAT64_SERVICE:-Wi-Fi}"

# Test destination
TEST_DOMAIN="github.com"

usage() {
    cat <<EOF
NAT64 DNS64 helper for macOS

Usage:
  $0 enable
  $0 disable
  $0 status

Commands:
  enable    Configure NAT64 DNS64
  disable   Restore automatic DNS
  status    Check DNS configuration and connectivity

Environment variables:
  NAT64_SERVICE          macOS network service (default: Wi-Fi)
  NAT64_DNS64_SERVER     DNS64 resolver (default: $DNS64_SERVER)
EOF
    exit 1
}

check_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "Error: This script is intended for macOS."
        exit 1
    fi
}

check_dependencies() {
    local missing=()

    for cmd in networksetup dig curl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        echo "Error: Missing required commands: ${missing[*]}"
        exit 1
    fi
}

check_service() {
    if ! networksetup -listallnetworkservices |
        grep -Fxq "$SERVICE"; then
        echo "Error: Network service '$SERVICE' was not found."
        echo
        echo "Available network services:"
        networksetup -listallnetworkservices
        exit 1
    fi
}

require_sudo() {
    echo "Administrator privileges are required."
    sudo -v
}

flush_dns_cache() {
    echo "Flushing macOS DNS cache..."

    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder 2>/dev/null || true
}

enable_nat64() {
    check_service
    require_sudo

    echo "Configuring NAT64 DNS64..."
    echo "Network service: $SERVICE"
    echo "DNS64 resolver:  $DNS64_SERVER"

    sudo networksetup -setdnsservers "$SERVICE" "$DNS64_SERVER"

    flush_dns_cache

    echo
    echo "DNS configuration:"
    networksetup -getdnsservers "$SERVICE"

    echo
    echo "Testing DNS64 synthesis..."

    if ! dig @"$DNS64_SERVER" AAAA "$TEST_DOMAIN" +short; then
        echo "Warning: DNS64 lookup failed."
        exit 1
    fi

    echo
    echo "Testing GitHub connectivity..."

    if curl -6 -I --connect-timeout 12 "https://$TEST_DOMAIN"; then
        echo
        echo "NAT64 connectivity test successful."
    else
        echo
        echo "Warning: GitHub connectivity test failed."
        echo "Check IPv6 connectivity and NAT64 resolver availability."
        exit 1
    fi
}

disable_nat64() {
    check_service
    require_sudo

    echo "Restoring automatic DNS for $SERVICE..."

    sudo networksetup -setdnsservers "$SERVICE" Empty

    flush_dns_cache

    echo
    echo "Current DNS configuration:"
    networksetup -getdnsservers "$SERVICE"

    echo
    echo "Automatic DNS restored."
}

status_nat64() {
    check_service

    echo "=================================="
    echo " NAT64 DNS64 status"
    echo "=================================="

    echo
    echo "Network service: $SERVICE"

    echo
    echo "Configured DNS servers:"
    networksetup -getdnsservers "$SERVICE"

    echo
    echo "DNS64 synthesis test:"
    dig @"$DNS64_SERVER" AAAA "$TEST_DOMAIN"

    echo
    echo "GitHub connectivity test:"
    curl -6 -I --connect-timeout 12 "https://$TEST_DOMAIN"
}

main() {
    check_macos
    check_dependencies

    case "${1:-}" in
        enable)
            enable_nat64
            ;;
        disable)
            disable_nat64
            ;;
        status)
            status_nat64
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"

