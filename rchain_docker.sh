#!/bin/bash
# Yes, in the future, I want to change this to use a config.toml, but for now it's convenient in a single file... 

# RCHAIN VARIABLES - You should change all of these.
RCHAINVERSION="<rnode version to run>"
RCHAINPRIVKEY="<insert priv key>"
RCHAINBOOTSTRAP="<insert bootstrap node>"
BONDSURL="<https url to bonds file>"
WALLETURL="<https url to wallets file>"

# DOCKER VARIABLES - You may need to change these depending on if you followed my readme and created the same dockernetwork name I specified there.
# This will open both of these ports below in iptables, but you may also need to open ports on your firewall if you have one (For example on AWS you will need to modify your security group to add these ports).
LOCALDATADIR="$HOME/rnode"
DOCKERNAME="rchain-node"
DOCKERNETWORK="rnode-net"
RPCPORT="40400"
STATSPORT="40403"
RCHAINDATADIR="/var/lib/rnode"

read -p "This script will remove any docker images named $DOCKERNAME and also delete the contents of $LOCALDATADIR and replace them with the bonds and wallet files you specified above. Press any key to continue."

# Check for docker container $DOCKERNAME and delete if it exists
docker container stop $DOCKERNAME
docker container rm $DOCKERNAME --force

# Delete local data directory
sudo rm -rf $LOCALDATADIR

# Create local data directory and download wallet / bonds files
mkdir -p "$LOCALDATADIR/genesis"
cd "$LOCALDATADIR/genesis"
wget $WALLETURL
wget $BONDSURL

BONDSFILE=`echo "$BONDSURL" | sed 's|.*/||'`
mv "$BONDSFILE" "bonds.txt"

# Pull docker image
docker pull rchain/rnode:$RCHAINVERSION

# Run docker command
docker run -d -u root --name $DOCKERNAME --network $DOCKERNETWORK -it -p $RPCPORT:$RPCPORT -p $STATSPORT:$STATSPORT -v $LOCALDATADIR:$RCHAINDATADIR rchain/rnode:$RCHAINVERSION run --bootstrap $RCHAINBOOTSTRAP --bonds-file $RCHAINDATADIR/genesis/bonds.txt --wallets-file $RCHAINDATADIR/genesis/wallets.txt --deploy-timestamp 1 --required-sigs 10 --validator-private-key $RCHAINPRIVKEY -p $RPCPORT

base64 -d <<<"H4sIAONTj1sAA71RQQ6AMAi78wqe61ESp4mJn+MlzmULG1R3c+HQFGgZ6L6oi3Qwe67QMZ8h6PYNtcd4amjTtD7hHRpf42q8mIjMNMSPZa00pEyn92G4hCgc+X60sBOZ/n3w9lVvv47eoumM2tS5gEp8b7R1yFnSSz7OmSrHZDbY0HhtUPnJgWSVIv7p0Q1vjkY1SQMAAA==" | gunzip

echo -e "TO SEE LOGS RUN: tail -f $LOCALDATADIR/rnode.log | grep --color -E '^|expected'"

echo -e "TO SEE BLOCKS RUN: docker exec -it rchain-node /opt/docker/bin/rnode show-blocks"
