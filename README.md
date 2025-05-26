<p align="center">
  <img height="100" height="auto" src="https://github.com/user-attachments/assets/a0408d8b-d3c1-4dc5-8e3c-79802d6b3053">
</p>

# Empeiria Testnet — empe-testnet-2

Official documentation:
>- [Validator setup instructions](https://docs.empe.io)

Explorer:
>- [Explorer](https://testnet.empe.explorers.guru)

### Minimum Hardware Requirements
 - 4x CPUs; the faster clock speed the better
 - 8GB RAM
 - 100GB of storage (SSD or NVME)

### Recommended Hardware Requirements 
 - 8x CPUs; the faster clock speed the better
 - 16GB RAM
 - 1TB of storage (SSD or NVME)

 - Ubuntu 22.04

## Set up your artela fullnode
```
wget https://raw.githubusercontent.com/freshe4qa/empeiria/main/empeiria.sh && chmod +x empeiria.sh && ./empeiria.sh
```

## Post installation

When installation is finished please load variables into system
```
source $HOME/.bash_profile
```

Synchronization status:
```
emped status 2>&1 | jq .SyncInfo
```

### Create wallet
To create new wallet you can use command below. Don’t forget to save the mnemonic
```
emped keys add $WALLET
```

Recover your wallet using seed phrase
```
emped keys add $WALLET --recover
```

To get current list of wallets
```
emped keys list
```

## Usefull commands
### Service management
Check logs
```
journalctl -fu emped -o cat
```

Start service
```
sudo systemctl start emped
```

Stop service
```
sudo systemctl stop emped
```

Restart service
```
sudo systemctl restart emped
```

### Node info
Synchronization info
```
emped status 2>&1 | jq .SyncInfo
```

Validator info
```
emped status 2>&1 | jq .ValidatorInfo
```

Node info
```
emped status 2>&1 | jq .NodeInfo
```

Show node id
```
emped tendermint show-node-id
```

### Wallet operations
List of wallets
```
emped keys list
```

Recover wallet
```
emped keys add $WALLET --recover
```

Delete wallet
```
emped keys delete $WALLET
```

Get wallet balance
```
emped query bank balances $EMPEIRIA_WALLET_ADDRESS
```

Transfer funds
```
emped tx bank send $EMPEIRIA_WALLET_ADDRESS <TO_EMPEIRIA_WALLET_ADDRESS> 10000000uempe
```

### Voting
```
emped tx gov vote 1 yes --from $WALLET --chain-id=$EMPEIRIA_CHAIN_ID
```

### Staking, Delegation and Rewards
Delegate stake
```
emped tx staking delegate $EMPEIRIA_VALOPER_ADDRESS 10000000uempe --from=$WALLET --chain-id=$EMPEIRIA_CHAIN_ID --gas=auto
```

Redelegate stake from validator to another validator
```
emped tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 10000000uempe --from=$WALLET --chain-id=$EMPEIRIA_CHAIN_ID --gas=auto
```

Withdraw all rewards
```
emped tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$EMPEIRIA_CHAIN_ID --gas=auto
```

Withdraw rewards with commision
```
emped tx distribution withdraw-rewards $EMPEIRIA_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$EMPEIRIA_CHAIN_ID
```

Unjail validator
```
emped tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$EMPEIRIA_CHAIN_ID \
  --gas=auto
```
