# ss-tun
This script sets up a L3 proxy backed by Shadowsocks

## Why bother using it?

[Shadowsocks](https://github.com/shadowsocks/shadowsocks-rust) is an application level (SOCKS5) proxy that can be used only when your application supports it.

With [tun2socks](https://github.com/xjasonlyu/tun2socks/), you can convert any application level proxy into VPN, which means your routing table changes and your network packets will be sent through a virtual network interface (created by tun2socks). Eventually all TCP/UDP traffic on your system will go through Shadowsocks as if Shadowsocks was a real gateway.

As we all know, DNS in China is heavily polluted. It's necessary for us to use DoH (DNS over HTTPS), which can be proxied by Shadowsocks. Hence, this project uses [doh-proxy](https://github.com/tinkernels/doh-proxy) for such purposes.

## How to use it?

### Windows (10 and above)

1. Edit `ss_config.json`
2. Run `ss-switch.bat`
3. Check output of the script, and test your connectivity
4. Run `ss-switch.bat` again to disable ss-tun, and follow on-screen instructions

### Linux

#### as a systemd service
1. Edit `ss_config.json`
2. Run `install.sh`
3. Use `systemctl start/stop ss-tun.service` to toggle

#### one-shot
Put required binaries in `$PATH`

1. Edit `ss_config.json`
2. Run `./ss-tun` to start
2. Run `./ss-tun stop` to stop
