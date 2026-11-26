## Router

This is my setup for a basic home router with nftables, systemd-networkd and unbound. The server is running Debian Stable and uses two network interfaces, eno1 (WAN) and eno2 (LAN). My ISP only supports IPv4.

### systemd-networkd

I recently switched to systemd-networkd for the network configuration. It feels like a more modern option to ifupdown (which is default on Debian installations without GUI) and also has a built-in DHCP client and server. It can also do DHCPv6 + prefix delegation and advertise prefixes via Router Advertisements if needed.

**/etc/systemd/networkd.conf.d/10-forwarding.conf**

```ini
[Network]
IPv4Forwarding=yes
```

Enable global IPv4 forwarding. It will modify related sysctl options for us.

One thing I noticed regarding IPv6 forwarding, which also is mentioned under the `IPv6AcceptRA` option in the manual, is that systemd-networkd uses their own userspace implementation of the IPv6 RA protocol.

If you enable IPv6 forwarding with sysctl, systemd-networkd will accept RAs on all its managed interfaces. If you enable forwarding with `IPv6Forwarding=yes` in systemd-networkd instead, it will behave similar to the kernel where we need to configure an interface to accept RAs if forwarding is enabled.

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

I use `UseDNS=no` because my `/etc/resolv.conf` just points to `127.0.0.1`. Even if systemd-networkd never modifies this file, it still add routes to the DNS servers in the routing table which feels unnecessary.

My ISP doesn't support IPv6 to customers but it still sends out IPv6 Router Advertisements and is added as the default gateway. It is not reachable so it doesn't really matter, but this is mostly to see if anything changes some day.

`IPv6AcceptRA=yes` is already the default behavior (unless IPv6Forwarding is enabled) but this makes it a bit more clear.

`DHCPv6Client=no` is to stop trigger the start of the DHCPv6 client from Router Advertisements with "managed" or "other configuration" flag. Could probably be removed if/when actual IPv6 support happens.

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
