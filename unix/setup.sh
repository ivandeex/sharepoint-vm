#!/bin/bash
. /etc/default/sharepoint
set -x

if [[ ${UNIX_ETHERNET2} ]]; then
    cat > /etc/netplan/localip.yaml <<-EOF
	network:
	  version: 2
	  renderer: networkd
	  ethernets:
	    ${UNIX_ETHERNET2}:
	      dhcp4: no
	      addresses: [${UNIX_LOCALIP}/24]
	EOF
    netplan apply
fi

sed -ire "s/^#*DNS=.*/DNS=${ADDC_LOCALIP}/" /etc/systemd/resolved.conf
systemctl restart systemd-resolved

add-apt-repository -y ppa:longsleep/golang-backports
apt-get -qqy install golang-1.14 build-essential
echo "PATH=\${PATH}:/usr/lib/go-1.14/bin" > /etc/profile.d/golang.sh

cd ~ubuntu
sudo -Hu ubuntu git clone https://github.com/rclone/rclone
