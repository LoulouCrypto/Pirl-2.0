# Script by LoulouCrypto thx to packetflow | Official PirlTeam
# https://www.louloucrypto.fr
# If you want to support me
# My pirl2.0 wallet : 
# 5CoVebZgbJ2brzuQhBtSHwuF4qT95mJiFb4KShiyfpkXSomQ

systemctl stop pirl
source $HOME/.cargo/env
rm -r pirl-2_0
git clone https://github.com/pirl/pirl-2_0
cd pirl-2_0
sleep 2
rustup toolchain install nightly-2020-10-06
rustup update nightly
rustup update stable
rustup target add wasm32-unknown-unknown --toolchain nightly-2020-10-06-x86_64-unknown-linux-gnu
sleep 2
git fetch --all --tags
git checkout 0.8.25
sleep 2
cargo +nightly-2020-10-06-x86_64-unknown-linux-gnu build --release
sleep 2
rm -rf .local/share/pirl/
sleep 2
cp -rpf target/release/pirl /usr/bin/pirl
clear
echo -e "Waiting 30 sec"
sleep 30
curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' http://localhost:9933
