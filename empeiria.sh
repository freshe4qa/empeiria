#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export EMPEIRIA_CHAIN_ID=empe-testnet-2" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages
sudo apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 screen bc fail2ban -y

# install go
VER="1.22.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

# download binary
curl -L https://github.com/CosmWasm/wasmvm/releases/download/v1.5.0/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv -f libwasmvm.x86_64.so /usr/lib/libwasmvm.x86_64.so

cd $HOME & rm -rf bin
mkdir bin
cd $HOME/bin
curl -LO https://github.com/empe-io/empe-chain-releases/raw/master/v0.3.0/emped_v0.3.0_linux_amd64.tar.gz
tar -xvf emped_v0.3.0_linux_amd64.tar.gz
chmod +x $HOME/bin/emped
mv $HOME/bin/emped ~/go/bin

# config
emped config chain-id $EMPEIRIA_CHAIN_ID
emped config keyring-backend os

# init
emped init $NODENAME --chain-id $EMPEIRIA_CHAIN_ID

# download genesis and addrbook
wget -O $HOME/.empe-chain/config/genesis.json https://server-5.itrocket.net/testnet/empeiria/genesis.json
wget -O $HOME/.empe-chain/config/addrbook.json  https://server-5.itrocket.net/testnet/empeiria/addrbook.json

# set minimum gas price
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0001uempe"|g' $HOME/.empe-chain/config/app.toml

# set peers and seeds
SEEDS=""
PEERS="03aa072f917ed1b79a14ea2cc660bc3bac787e82@empeiria-testnet-peer.itrocket.net:28656,e9bc1f172156396f816b6255135cdd0f9272fd83@176.9.126.78:10656,106b4f4e333bd04d2b93768dace23bae12ebc1b7@65.109.112.148:21156,e058f20874c7ddf7d8dc8a6200ff6c7ee66098ba@65.109.93.124:29056,45bdc8628385d34afc271206ac629b07675cd614@65.21.202.124:25656,91fb8e75a4b92589211d47d5a9ce934d32733043@116.202.48.104:26656,2db322b41d26559476f929fda51bce06c3db8ba4@65.109.24.155:11256,384746ace33ecbbeb349bac2e6163606debe0e78@136.243.105.186:23656,a9cf0ffdef421d1f4f4a3e1573800f4ee6529773@136.243.13.36:29056,38ca15d129e9f02ff4164649f1e8ba1325237e7f@194.163.145.153:26656,78f766310a83b6670023169b93f01d140566db79@65.109.83.40:29056"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.empe-chain/config/config.toml

# disable indexing
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.empe-chain/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.empe-chain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.empe-chain/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.empe-chain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.empe-chain/config/app.toml
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.empe-chain/config/app.toml

#be
#sed -i -e "s/^app-db-backend *=.*/app-db-backend = \"goleveldb\"/;" $HOME/.empe-chain/config/app.toml
#sed -i -e "s/^db_backend *=.*/db_backend = \"pebbledb\"/" $HOME/.empe-chain/config/config.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.empe-chain/config/config.toml

# create service
sudo tee /etc/systemd/system/emped.service > /dev/null << EOF
[Unit]
Description=Empeiria node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which emped) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# reset
emped tendermint unsafe-reset-all --home $HOME/.empe-chain --keep-addr-book
curl https://server-5.itrocket.net/testnet/empeiria/empeiria_2025-05-26_5082739_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.empe-chain

# start service
sudo systemctl daemon-reload
sudo systemctl enable emped
sudo systemctl restart emped

break
;;

"Create Wallet")
emped keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
EMPEIRIA_WALLET_ADDRESS=$(emped keys show $WALLET -a)
EMPEIRIA_VALOPER_ADDRESS=$(emped keys show $WALLET --bech val -a)
echo 'export EMPEIRIA_WALLET_ADDRESS='${EMPEIRIA_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export EMPEIRIA_VALOPER_ADDRESS='${EMPEIRIA_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Create Validator")
emped tx staking create-validator \
--amount=1000000uempe \
--pubkey=$(emped tendermint show-validator) \
--moniker=$NODENAME \
--chain-id=empe-testnet-2 \
--commission-rate=0.05 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation=1 \
--from=wallet \
--fees=30uempe \
--gas=300000 \
--gas-adjustment 1.5 \
-y 
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
