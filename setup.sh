#!/bin/bash
set -ex

AP_SSID="WIFI_SSID"
AP_PASSWORD="WIFI_PASSWORD"
WG_PRIVKEY="WIREGUARD_LOCAL_PRIVATE_KEY"
WG_PUBKEY="WIREGUARD_REMOTE_PUBLIC_KEY"
WLAN_IFACE="WLAN_INTERFACE_ID"
ENDPOINT_HOST="WIREGUARD_REMOTE_HOST"
ENDPOINT_PORT="WIREGUARD_REMOTE_PORT"

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

apt install dnsmasq hostapd -y

mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
touch /etc/dnsmasq.conf 
echo "interface=wlan0" >> /etc/dnsmasq.conf
echo "dhcp-range=192.168.100.2,192.168.100.100,255.255.255.0,24h" >> /etc/dnsmasq.conf
systemctl reload dnsmasq
systemctl enable dnsmasq

echo "interface wlan0" >> /etc/dhcpcd.conf
echo "    static ip_address=192.168.100.1/24" >> /etc/dhcpcd.conf
echo "    nohook wpa_supplicant" >> /etc/dhcpcd.conf
systemctl restart dhcpcd

echo DAEMON_CONF=\"/etc/hostapd/hostapd.conf\" >> /etc/default/hostapd
sed -i -e "s/<AP_SSID>/$AP_SSID/g" etc/hostapd/hostapd.conf
sed -i -e "s/<AP_PASSWORD>/$AP_PASSWORD/g" etc/hostapd/hostapd.conf
cp etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd

apt install raspberrypi-kernel-headers -y
echo "deb http://deb.debian.org/debian/ unstable main" | sudo tee --append /etc/apt/sources.list.d/unstable.list
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' | sudo tee --append /etc/apt/preferences.d/limit-unstable
apt install dirmngr -y
apt-key adv --keyserver   keyserver.ubuntu.com --recv-keys 8B48AD6246925553
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7638D0442B90D010
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
apt update
apt install build-essential pkg-config libmnl-dev libelf-dev wireguard -y

sed -i -e "s/<WG_PRIVKEY>/$WG_PRIVKEY/g" etc/wireguard/pinet.conf
sed -i -e "s/<WG_PUBKEY>/$WG_PUBKEY/g" etc/wireguard/pinet.conf
sed -i -e "s/<WLAN_IFACE>/$WLAN_IFACE/g" etc/wireguard/pinet.conf
sed -i -e "s/<ENDPOINT_HOST>/$ENDPOINT_HOST/g" etc/wireguard/pinet.conf
sed -i -e "s/<ENDPOINT_PORT>/$ENDPOINT_PORT/g" etc/wireguard/pinet.conf
cp etc/wireguard/pinet.conf /etc/wireguard/pinet.conf
cp lib/systemd/system/pinet.service /lib/systemd/system/pinet.service
cp etc/wg.sh /etc/wg.sh
chmod +x /etc/wg.sh
cp etc/wgoff.sh /etc/wgoff.sh
chmod +x /etc/wgoff.sh
