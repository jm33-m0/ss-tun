#!/bin/bash

info() {
    echo -e "\e[34m$1\e[0m"
}

success() {
    echo -e "\e[32m$1\e[0m"
}

error() {
    echo -e "\n\e[31m$1\e[0m\n"
    exit 1
}

is_cmd_exist() {
    command -v "$1" || {
        error "command $1 not found"
    }
}

[[ "$EUID" -eq 0 ]] || error "Run me as root"

is_cmd_exist ip
is_cmd_exist systemctl

(
    apt install jq curl resolvconf bind9-dnsutils -y || yum install -y curl jq resolvconf
) || error "failed to install jq/curl"

(cp -avR ./bin/* /usr/local/bin && chmod 755 /usr/local/bin/*) || error "failed to install binaries"

(
    [[ -d /etc/ss-tun ]] || mkdir /etc/ss-tun
    cp -avR ./dns.txt /etc/ss-tun/dns.txt
    cp -avR ./ss_config.json /etc/ss-tun/config.json
) || error "failed to install ss config, please name your shadowsocks config file as ./ss_config.json"

(
    cp -avR ./ss-tun.service /etc/systemd/system/ss-tun.service &&
        systemctl daemon-reload
) || error "failed to install service"

command -v curl && {
    curl -o /etc/ss-tun/chnroute.txt https://raw.githubusercontent.com/jm33-m0/switchyomega-china-list/main/chnroute.txt
}

[[ -f /etc/ss-tun/chnroute.txt ]] || error "/etc/ss-tun/chnroute.txt not found, please download from https://raw.githubusercontent.com/jm33-m0/switchyomega-china-list/main/chnroute.txt"

success "installed"
success "systemctl start ss-tun"
success "or\nsystemctl enable ss-tun\nto run ss-tun at boot"
