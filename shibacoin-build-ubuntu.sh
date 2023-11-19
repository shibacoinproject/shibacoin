#!/bin/sh

# =============================================================================#
# this script can use for Ubuntu 18.04 LTS and Ubuntu 20.04 LTS
# recommended use linux fresh installer
# copy this file into root folder
# make to the executable file with command :
# chmod +x shibacoin-build-ubuntu.sh 
# ./shibacoin-build-ubuntu.sh
# =============================================================================#

# added swapfile ( you can change swapfile allocate in : fallocate -l 3G /swapfile

swapoff -a
fallocate -l 2G /swapfile  
chown root:root /swapfile  
chmod 0600 /swapfile  
sudo bash -c "echo 'vm.swappiness = 10' >> /etc/sysctl.conf"  
mkswap /swapfile  
swapon /swapfile    
echo '/swapfile none swap sw 0 0' >> /etc/fstab
free -m 
df -h

# Prepare to build, Update your Ubuntu server
cd ~ && sudo apt-get update && sudo apt-get upgrade -y &&

# Install the required dependencies
sudo apt-get install build-essential bsdmainutils libtool autotools-dev libboost-all-dev libssl-dev libevent-dev libprotobuf-dev protobuf-compiler pkg-config python3 -y &&

sudo apt-get install cmake automake unzip net-tools -y &&

# port UPnP
sudo apt-get install libminiupnpc-dev libzmq3-dev -y &&

# (provides ZMQ API 4.x)
sudo apt-get install libzmq3-dev -y &&

# Qt 5 with GUI
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler -y &&

# libqrencode 
sudo apt-get install libqrencode-dev -y &&

# Install the repository ppa:bitcoin/bitcoin
sudo apt-get install software-properties-common -y &&
sudo add-apt-repository ppa:luke-jr/bitcoincore -y &&
sudo apt update -y && 
sudo apt upgrade -y

# Download shibacoin on github 

cd ~ 

git clone -b master --single-branch https://github.com/shibacoinproject/shibacoin.git

cd shibacoin

# Install libdb6.2 (Berkeley DB)

BITCOIN_ROOT=$(pwd)

# Pick some path to install BDB to, here we create a directory within the shibacoin directory
BDB_PREFIX="${BITCOIN_ROOT}/build"
mkdir -p $BDB_PREFIX

# Fetch the source and verify that it is not tampered with
wget 'http://download.oracle.com/berkeley-db/db-6.2.32.tar.gz'
echo 'a9c5e2b004a5777aa03510cfe5cd766a4a3b777713406b02809c17c8e0e7a8fb  db-6.2.32.tar.gz' | sha256sum -c
# -> db-6.2.32.tar.gz: OK
tar -xzvf db-6.2.32.tar.gz

# Build the library and install to our prefix
cd db-6.2.32/build_unix/
#  Note: Do a static build so that it can be embedded into the executable, instead of having to find a .so at runtime
../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_PREFIX
make install

# build and install shibacoin
cd $BITCOIN_ROOT

./autogen.sh

./configure --with-incompatible-bdb --enable-upnp-default LDFLAGS="-L${BDB_PREFIX}/lib/" CPPFLAGS="-I${BDB_PREFIX}/include/" CXXFLAGS="--param ggc-min-expand=1 --param ggc-min-heapsize=32768" --disable-tests --disable-bench --disable-gui-tests --disable-zmq --enable-hardening

make
 
make install

sudo ufw enable -y 
sudo ufw allow 44556/tcp
sudo ufw allow 33445/tcp
sudo ufw allow 22/tcp

sudo mkdir ~/.shibacoin

cat << "CONFIG" >> ~/.shibacoin/shibacoin.conf
daemon=1
txindex=1
staking=1
listen=1
server=1
rpcport=44556
port=33445
rpcuser=SWmtLhap34m213BDaVWghQcRuMBwP4pdPM
rpcpassword=c=SHIBA
rpcconnect=127.0.0.1
rpcallowip=127.0.0.1
addnode=dnsseed1.shibamore.cloud
addnode=dnsseed2.shibamore.cloud
addnode=dnsseed3.shibamore.cloud
addnode=dnsseed4.shibamore.cloud
addnode=dnsseed5.shibamore.cloud
addnode=dnsseed6.shibamore.cloud
CONFIG

chmod 700 ~/.shibacoin/shibacoin.conf
chmod 700 ~/.shibacoin
ls -la ~/.shibacoin 
cd ~
cd /usr/local/bin 

shibacoind -daemon -txindex -reindex
