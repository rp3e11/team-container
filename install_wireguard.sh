#!/usr/bin/env bash

DIST=$(lsb_release -is)
RELEASE=$(lsb_release -rs)

echo $RELEASE
echo $DIST

SETUP=false

# install wiredguard, ufw and fail2ban from sources - depends on operating system
if [ "$DIST" == "Ubuntu" ]
then
  if [ "$RELEASE" == "18.04" ] 
  then
    SETUP=true
    sudo add-apt-repository ppa:wireguard/wireguard
  fi
  if [ "$RELEASE" == "20.04" ]
  then
    SETUP=true
  fi
  if [ $SETUP ]
  then
    sudo apt-get update && sudo apt-get dist-upgrade -y && sudo apt-get install wireguard ufw -y
  fi
fi

# operating system independent setup
if [ $SETUP ] 
then
  wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
  cp wireguard/wg0.conf wg0.conf
  sed -i "s/INTF_REPLACE/$(sudo cat /etc/wireguard/privatekey)/" wg0.conf
  sed -i "s/INTF_REPLACE/$(ip -o -4 route show to default | awk '{print $5}')/" wg0.conf
  sudo mv wg0.conf /etc/wireguard/wg0.conf
  sudo chmod 600 /etc/wireguard/{privatekey,wg0.conf}
  sudo wg-quick up wg0
  sudo systemctl enable wg-quick@wg0
  
  # setup ufw
  ufw allow 22
  ufw default deny incoming
  ufw default deny outgoing
  ufw allow from 10.0.1.1/24 
  ufw allow 51820/udp

fi
