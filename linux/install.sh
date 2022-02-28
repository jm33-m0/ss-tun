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

is_cmd_exist ip
is_cmd_exist systemctl

[[ "$EUID" -eq 0 ]] || error "Run me as root"

(cp -avR ./bin/* /usr/local/bin && chmod 755 /usr/local/bin/*) || error "failed to install binaries"

(
    [[ -d /etc/ss-tun ]] || mkdir /etc/ss-tun
    cp -avR ./ss_config.json /etc/ss-tun/config.json
) || error "failed to install ss config"

(
    cp -avR ./ss-tun.service /etc/systemd/system/ss-tun.service &&
        systemctl daemon-reload
) || error "failed to install service"

success "installed"
success "systemctl start ss-tun"
success "or\nsystemctl enable ss-tun\nto run ss-tun at boot"
