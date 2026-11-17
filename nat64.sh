
#!/usr/bin/env bash

set -euo pipefail

CONNECTION="WIFI_NAME"
DNS64_SERVER="2a01:4f9:c010:3f02::1"

usage() {
    echo "Usage: $0 {enable|disable|status}"
    exit 1
}

enable_nat64() {
    echo "Enabling NAT64 DNS64..."

    sudo nmcli connection modify "$CONNECTION" \
        ipv4.ignore-auto-dns yes \
        ipv6.ignore-auto-dns yes \
        ipv4.dns "" \
        ipv6.dns "$DNS64_SERVER"

    sudo nmcli connection up "$CONNECTION"

    echo
    echo "Checking DNS configuration..."
    resolvectl status

    echo
    echo "Testing GitHub..."
    curl -6 -I --connect-timeout 12 https://github.com

    echo
    echo "NAT64 DNS64 enabled successfully."
}

disable_nat64() {
    echo "Restoring automatic DNS..."

    sudo nmcli connection modify "$CONNECTION" \
        ipv4.ignore-auto-dns no \
        ipv6.ignore-auto-dns no \
        ipv4.dns "" \
        ipv6.dns ""

    sudo nmcli connection up "$CONNECTION"

    echo "Automatic DNS restored."
}

status_nat64() {
    echo "Current DNS configuration:"
    resolvectl status

    echo
    echo "Testing DNS64 synthesis..."
    dig @"$DNS64_SERVER" AAAA github.com

    echo
    echo "Testing GitHub connectivity..."
    curl -6 -I --connect-timeout 12 https://github.com
}

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

