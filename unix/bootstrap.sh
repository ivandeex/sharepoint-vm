#!/bin/bash
{
echo "script started"
### set script parameters
username="ubuntu"
user_id="1000"
ssh_port="22"
public_key="${public_key}"
set -x
### change ssh port
sed -i /etc/ssh/sshd_config -E -e "s/^#?Port [0-9].*/Port $ssh_port/"
systemctl restart ssh
### install our public ssh key for root
mkdir -p /root/.ssh/
echo "$public_key" > /root/.ssh/authorized_keys
chown root:root /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
### create our user
useradd -m -s /bin/bash -u $user_id $username
### install our public ssh key for user
mkdir -p /home/$username/.ssh
touch /home/$username/.ssh/authorized_keys
echo "$public_key" >> /home/$username/.ssh/authorized_keys
chown -R $user_id:$user_id /home/$username/.ssh
chmod 600 /home/$username/.ssh/authorized_keys
### remove requiretty from sudoers
sed -i /etc/sudoers -E -e '/^Defaults\s+requiretty/d'
### enable sudoers for our user
echo "$username ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$username
chown root:root /etc/sudoers.d/$username
chmod 440 /etc/sudoers.d/$username
### set random user/root password
random_pass=$(head -c1024 /dev/urandom | md5sum | cut -d' ' -f1)
echo "$username:$random_pass" | chpasswd
echo "root:$random_pass" | chpasswd
#echo "note: setting user/root password to $random_pass" 1>&2
echo "script complete"
} > /var/log/bootstrap.log 2>&1
