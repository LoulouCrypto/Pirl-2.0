#!/bin/bash
# Script by LoulouCrypto
# https://www.louloucrypto.fr
# If you want to support me
# My pirl2.0 wallet : 
# 5CoVebZgbJ2brzuQhBtSHwuF4qT95mJiFb4KShiyfpkXSomQ


INSTALLFOLDER='pirl-2_0'
COIN_PATH='/usr/bin/'
#64 bit only
COIN_GIT='https://github.com/pirl/pirl-2_0'
#COIN_GIT='https://github.com/starkleytech/pirl-2_0'
COIN_PORT=30333
COIN_NAME='pirl'

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

progressfilt () {
  local flag=false c count cr=$'\r' nl=$'\n'
  while IFS='' read -d '' -rn 1 c
  do
    if $flag
    then
      printf '%c' "$c"
    else
      if [[ $c != $cr && $c != $nl ]]
      then
        count=0
      else
        ((count++))
        if ((count > 1))
        then
          flag=true
        fi
      fi
    fi
  done
}

function validator_name() {
  echo -e "Your are going to install a ${GREEN}Pirl 2.0 Validator${NC}. Please use crtl+c if you don't want to install it ."
  sleep 2
  echo
  echo -e "Enter your${GREEN} Pirl Validator${NC} name:"
  read -e VALNAME
 
clear
}

function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=Pirl Validator
After=network-online.target

[Service]

ExecStart=/usr/bin/pirl  --port "30333"   --ws-port "9944"   --rpc-port "9933" --validator  --name "$VALNAME"
User=root
Restart=always
ExecStartPre=/bin/sleep 5
RestartSec=30s


[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep pirl)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
	echo -e "fournalctl -fu $COIN_NAME"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}

function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow ssh >/dev/null 2>&1
  ufw allow ntp >/dev/null 2>&1
  ufw allow $COIN_PORT >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}

function detect_ubuntu() {
 if [[ $(lsb_release -d) == *18.04* ]]; then
   UBUNTU_VERSION=18
else
   echo -e "${RED}You are not running Ubuntu 18.04 Installation is cancelled.${NC}"
   exit 1
fi
}

function checks() {
 detect_ubuntu
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi
}

function prepare_system_for_download() {
echo -e "Prepare the system to install ${GREEN}$COIN_NAME${NC} Validator."
apt-get update >/dev/null 2>&1
apt-get upgrade -y >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" curl systemd figlet unzip make clang pkg-config libssl-dev build-essential ntp git >/dev/null 2>&1
curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt install systemd figlet unzip make clang pkg-config libssl-dev build-essential ntp git"
	echo "curl https://sh.rustup.rs -sSf | sh"
	echo "source $HOME/.cargo/env"
 exit 1
fi

clear
}

function pirl_compile() {
figlet -f slant "Pirl 2.0"
echo -e "Prepare compiling ${GREEN}$COIN_NAME${NC} Validator."
rustup toolchain install nightly-2020-10-06
rustup update nightly
rustup update stable
rustup target add wasm32-unknown-unknown --toolchain nightly-2020-10-06-x86_64-unknown-linux-gnu
clear
figlet -f slant "Pirl 2.0"
echo -e "Compiling ${GREEN}$COIN_NAME${NC} Validator."
cd ~
git clone $COIN_GIT
cd $INSTALLFOLDER
cargo +nightly-2020-10-06-x86_64-unknown-linux-gnu build --release
sleep 2
cp -rp target/release/pirl /usr/bin/
clear
}

function create_swap() {
 echo -e "Checking if swap space is needed."
 PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
 if [ "$PHYMEM" -lt "10" ]
  then
    echo -e "${GREEN}Server is running with less than 10G of RAM without SWAP, creating 20G swap file.${NC}"
    SWAPFILE=$(mktemp)
    dd if=/dev/zero of=$SWAPFILE bs=1024 count=20M
    chmod 600 $SWAPFILE
    mkswap $SWAPFILE
    swapon -a $SWAPFILE
 else
  echo -e "${GREEN}The server running with at least 10G of RAM, or a SWAP file is already in place.${NC}"
 fi
 clear
}

function important_information() {
figlet -f slant "Pirl 2.0"

 echo -e "Waiting 30 sec"
 sleep 30
 echo -e "================================================================================"
 echo -e "$COIN_NAME Validator is up and running."

   echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
   echo -e "Status: ${RED}systemctl status $COIN_NAME.service${NC}"
   echo -e "Journal: ${RED}journalctl -fu $COIN_NAME"${NC}
   echo -e "Your key for Submitting the setKeys Transaction :"
   curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' http://localhost:9933
 echo -e "================================================================================"
}

##### Main #####
clear
validator_name
checks
prepare_system_for_download
figlet -f slant "Pirl 2.0"
create_swap
sleep 2
enable_firewall
sleep 2
pirl_compile
sleep 2
configure_systemd
sleep 2
important_information


# Script by LoulouCrypto
# https://www.louloucrypto.fr
# If you want to support me
# My pirl2.0 wallet : 
# 5CoVebZgbJ2brzuQhBtSHwuF4qT95mJiFb4KShiyfpkXSomQ
