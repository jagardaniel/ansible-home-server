## Router

This is my setup for a basic home router with nftables, systemd-networkd and unbound. The server is running Debian Stable and uses two network interfaces, eno1 (WAN) and eno2 (LAN). My ISP only supports IPv4.

### Enable IP forwarding for IPv4

**/etc/sysctl.d/local.conf**

```ini
net.ipv4.ip_forward = 1
```

This can also be set with systemd-networkd in `/etc/systemd/networkd.conf.d/yourconfig.conf` with `IPv4Forwarding=yes` in the `[Network]` section.

### systemd-networkd

I recently switched to systemd-networkd for the network configuration. It feels like a more modern option to ifupdown (which is default on Debian installations without GUI) and also has a built-in DHCP client and server. It can also do DHCPv6 + prefix delegation and advertise prefixes via Router Advertisements.

**/etc/systemd/network/10-wan.network**

```ini
[Match]
Name=eno1

[Network]
DHCP=ipv4
IPv6AcceptRA=yes

[DHCPv4]
UseDNS=no

[IPv6AcceptRA]
DHCPv6Client=no
```

I use `UseDNS=no` because my `/etc/resolv.conf` just points to `127.0.0.1`. Even if systemd-networkd doesn't modify this file with this setting set to yes, it still add routes to the DNS servers in the routing table which feels unnecessary.

My ISP doesn't support IPv6 to customers but it still sends out IPv6 Router Advertisements. I accept it mainly because I can and hope that the default gateway is going to become reachable some day. `IPv6AcceptRA=yes` is already the default behavior (unless IPv6Forwarding is enabled) but this makes it more clear, especially since I have it set to "no" on the LAN interface.

`DHCPv6Client=no` to stop trigger the start of the DHCPv6 client from Router Advertisements with "managed" or "other configuration" flag. Could probably be removed if/when actual IPv6 support happens.

One note about IPv6 forwarding and Router Advertisements. Interfaces will not accept RAs if you enable IPv6 forwarding in the kernel (`net.ipv6.conf.all.forwarding = 1`). You have to enable it with `net.ipv6.conf.eno1.accept_ra = 2` for example. systemd-networkd seems to ignore this setting so it will accept RAs on all networkd managed interfaces even when IPv6 forwarding is enabled. It will not accept them if `IPv6Forwarding=yes` is set, so maybe it makes more sense to set IPv6 forwarding with systemd-networkd instead of sysctl if you want to get similar behavior.

**/etc/systemd/network/20-lan.network**

```ini
[Match]
Name=eno2

[Network]
Address=192.168.0.1/24
IPv6AcceptRA=no
DHCPServer=yes

[DHCPServer]
PoolOffset=50
DNS=192.168.0.1
```

DHCP server with the pool `192.168.0.50 - 192.168.0.254`. Don't accept Router Advertisements from the local network (looking at you, Apple TV), so use `IPv6AcceptRA=no`. This setting is not needed if `IPv6SendRA=yes` is set, but we don't use that yet.

### nftables (firewall + NAT)

**/etc/nftables.conf**

```ini
#!/usr/sbin/nft -f

# Interfaces
define WAN_IF = eno1
define LAN_IF = eno2

# Local network
define LAN_NET = 192.168.0.0/24

# External address for source NAT
define WAN_IP = 37.xx.xx.xx

# Flush current ruleset
flush ruleset

table inet firewall {
        chain input {
                type filter hook input priority 0; policy drop;

                ct state vmap { established : accept, related : accept, invalid : drop }

                iif { lo, $LAN_IF } accept

                ip protocol icmp limit rate 10/second accept
                ip6 nexthdr icmpv6 accept

                tcp dport { 22, 30033 } accept
                udp dport { 9987, 33434-33464 } accept
        }

        chain forward {
                type filter hook forward priority 0; policy drop;

                ct state vmap { established : accept, related : accept, invalid : drop }

                iif $LAN_IF accept
        }
}

table ip nat {
        chain postrouting {
                type nat hook postrouting priority 100; policy accept;

                ip saddr $LAN_NET oif $WAN_IF snat to $WAN_IP
        }
}
```

### unbound

Forward all DNS requests from the local network to Cloudflares DNS servers.

**/etc/unbound/unbound.conf.d/unbound.conf**

```ini
server:
    interface: 127.0.0.1
    interface: ::1
    interface: 192.168.0.1

    ip-freebind: yes

    access-control: 192.168.0.0/24 allow

    root-hints: "/usr/share/dns/root.hints"
    auto-trust-anchor-file: "/var/lib/unbound/root.key"

    qname-minimisation: yes
    verbosity: 1

    extended-statistics: yes

remote-control:
    control-enable: yes
    control-interface: /run/unbound.ctl

forward-zone:
    name: "."
    forward-addr: 1.1.1.1
    forward-addr: 1.0.0.1
```
