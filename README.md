# ss-tun

This script sets up a L3 proxy backed by Shadowsocks

## Why should I use it

[Shadowsocks](https://github.com/shadowsocks/shadowsocks-rust) is an application level (SOCKS5) proxy that can only be used when your application support it

With [tun2socks](https://github.com/xjasonlyu/tun2socks/), you can convert application level proxy into VPN, meaning your routing table changes and your network packets will be sent through a virtual network interface (that tun2socks creates), eventually all TCP/UDP traffic on your system will go through Shadowsocks as if Shadowsocks were a real gateway

As we all know, DNS in China is heavily polluted, it's necessary for us to use DoH (DNS over HTTPS), which can be proxied by Shadowsocks. This project uses [nextdns](https://github.com/nextdns/nextdns) for this purpose

## How to use

- Edit `ss_config.json`
- Run `ss-switch.bat`
- Check output of the script, and test your connectivity
- Run `ss-switch.bat` again to disable ss-tun, follow on-screen instructions
