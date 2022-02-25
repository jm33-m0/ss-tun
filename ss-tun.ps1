$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host -ForegroundColor Red "I need Admin for this" 
    exit 1
}

$ss_gw = "11.11.11.11" # ip of the tun device
$lock = "ss-tun.lock"
$ss_config = Get-Content -Path .\ss_config.json | ConvertFrom-Json
$ss_server = $ss_config.server + "/32"

if (Test-Path -Path $lock) {
    Write-Host -ForegroundColor Yellow "Seems like ss-tun is running"
    # read gw info from lock file
    $gw_recovery = Get-Content -Path .\ss-tun.lock | ConvertFrom-Json
    $gw_re = $gw_recovery.gw
    $gw_idx_re = $gw_recovery.gw_ifindex

    if ((Get-NetAdapter).Name -contains "tun114514") {
        # unset gw
        Remove-NetRoute -DestinationPrefix 0.0.0.0/1 -NextHop $ss_gw -Confirm:$false
        Remove-NetRoute -DestinationPrefix 128.0.0.0/1 -NextHop $ss_gw -Confirm:$false

        # unset previously added routes
        Remove-NetRoute -DestinationPrefix $ss_server -NextHop $gw_re -InterfaceIndex $gw_idx_re -Confirm:$false
        Remove-NetRoute -DestinationPrefix 10.0.0.0/8 -NextHop $gw_re -InterfaceIndex $gw_idx_re -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -DestinationPrefix 192.168.0.0/16 -NextHop $gw_re -InterfaceIndex $gw_idx_re -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -DestinationPrefix 172.16.0.0/12 -NextHop $gw_re -InterfaceIndex $gw_idx_re -Confirm:$false -ErrorAction SilentlyContinue

        Stop-Process -Name tun2socks
        Stop-Process -Name sslocal
        Stop-Process -Name doh-proxy
    }
    Remove-Item -Path $lock

    $decision = $Host.UI.PromptForChoice('Restart?', 'Do you want to close ss-tun or restart it?', @('&Restart'; '&Close'), 1)
    if ($decision) {
        Write-Host -ForegroundColor Green "ss-tun has been closed"
        exit 0
    }
}

# recover gateway from lock file 
$gw = $gw_re
$gw_ifindex = $gw_idx_re

# find gateway
$gws = Get-NetRoute "0.0.0.0/0"
foreach ($gw_choice in $gws) {
    $use_gw = $Host.UI.PromptForChoice($gw_choice.NextHop + " " + $gw_choice.ifIndex, "Is this your default gateway?", @('&No'; '&Yes'), 1)
    if ($use_gw) {
        $gw = $gw_choice.NextHop
        $gw_ifindex = $gw_choice.ifIndex
        break
    }
}


$ss_proc = Start-Process -FilePath .\bin\sslocal.exe -ArgumentList "-c ss_config.json" -WindowStyle Hidden -RedirectStandardError .\logs\sslocal-error.log -RedirectStandardOutput .\logs\sslocal.log -PassThru
while (!($ss_proc.Id -gt 0)) {
    Write-Host -ForegroundColor Blue "Waiting for Shadowsocks"
    Start-Sleep -Seconds 1
}
Start-Process -FilePath .\bin\tun2socks.exe -ArgumentList "-loglevel error -device tun://tun114514 -proxy socks5://127.0.0.1:1080" -WindowStyle Hidden -RedirectStandardError .\logs\tun2socks-error.log -RedirectStandardOutput .\logs\tun2socks.log
Start-Process -FilePath .\bin\doh-proxy.exe -ArgumentList "-endpoint https://1.1.1.1/dns-query" -WindowStyle Hidden -RedirectStandardError .\logs\doh-error.log -RedirectStandardOutput .\logs\doh.log


while (!((Get-NetAdapter).Name -contains "tun114514")) {
    Write-Host -ForegroundColor Blue "Waiting for tun114514 to go up" 
    Start-Sleep -Seconds 1
}


# Remove-NetRoute -DestinationPrefix 0.0.0.0/0 -NextHop $gw -Confirm:$false
# configure tun
New-NetIPAddress -IPAddress $ss_gw -PrefixLength 32 -InterfaceAlias tun114514 -Confirm:$false
# remove ipv6 addr (if any) since it's useless
Remove-NetIPAddress -AddressFamily IPv6 -InterfaceAlias tun114514 -Confirm:$false

# add gateway
New-NetRoute -DestinationPrefix 0.0.0.0/1 -NextHop $ss_gw -InterfaceAlias tun114514 -Confirm:$false
New-NetRoute -DestinationPrefix 128.0.0.0/1 -NextHop $ss_gw -InterfaceAlias tun114514 -Confirm:$false

# ss server goes thru old gateway
# and LAN addresses
# and Tsinghua mirrors
New-NetRoute -DestinationPrefix $ss_server -NextHop $gw -InterfaceIndex $gw_ifindex -Confirm:$false -ErrorAction SilentlyContinue
New-NetRoute -DestinationPrefix 10.0.0.0/8 -NextHop $gw -InterfaceIndex $gw_ifindex -Confirm:$false -ErrorAction SilentlyContinue
New-NetRoute -DestinationPrefix 192.168.0.0/16 -NextHop $gw -InterfaceIndex $gw_ifindex -Confirm:$false -ErrorAction SilentlyContinue
New-NetRoute -DestinationPrefix 172.16.0.0/12 -NextHop $gw -InterfaceIndex $gw_ifindex -Confirm:$false -ErrorAction SilentlyContinue
New-NetRoute -DestinationPrefix 101.4.0.0/14 -NextHop $gw -InterfaceIndex $gw_ifindex -Confirm:$false -ErrorAction SilentlyContinue

# take care of DNS
Set-DnsClientServerAddress -InterfaceAlias tun114514 -ServerAddresses "127.0.0.1" -Confirm:$false
Set-DnsClientServerAddress -InterfaceIndex $gw_ifindex -ServerAddresses "127.0.0.1" -Confirm:$false

# create lock file
# when this file exists, we say ss-tun is already running
$gw_config = @"
{
    "gw": "$gw",
    "gw_ifindex": "$gw_ifindex"
}
"@ 
$gw_config | Set-Content -Path $lock

Write-Host -ForegroundColor Green "If you see no errors, proceed to close this window and test your network"