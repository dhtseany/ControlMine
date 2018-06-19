#!/bin/bash

CURRENT_USER=$USER
SERVER=$1

# First check which coin we're dealing with on the remote node
COIN_RAW=`ssh -q -t $CURRENT_USER@$SERVER "cat /etc/coin.info"`
COIN_BASE=$(echo "$COIN_RAW" | cut -f1)
COIN_VER=$(echo "$COIN_RAW" | cut -f2)

# Next we set the appropriate tmp directory
if [[ ("$COIN_BASE" == "FGC") ]];
    then
        TMP_DIR=/tmp/fgc
fi

if [[ ("$COIN_BASE" == "AEG") ]];
    then
        TMP_DIR=/tmp/aeg
fi

# Then we set the run-as user for the installed coin
if [[ ("$COIN_BASE" == "FGC") ]];
    then
        C_USER="FantasyGold"
fi

if [[ ("$COIN_BASE" == "AEG") ]];
    then
        C_USER="Aegeus"
fi

# Set the build_dir
if [[ ("$COIN_BASE" == "FGC") ]];
    then
        BUILD_DIR=$TMP_DIR/fgc_build
fi

if [[ ("$COIN_BASE" == "AEG") ]];
    then
        BUILD_DIR=$TMP_DIR/aeg_build
fi

clear

# # Check if controlnodes.conf exists
# if [[ ! -d "controlnodes.conf" ]]
#         then
#                 echo "controlnodes.conf detected."
                
#         else
#                 echo "controlnodes.conf not detected, creating."
#                 touch controlnodes.conf
# fi

if [[ -z $2 ]];
    then
        echo "Control Mine v0.1 for CentOS 7."
        echo "Usage:"
        echo "$ ./newnode.sh <server> <action>"
        exit 0
fi

# # If the "all" is used load the value of each array into
# if [[ ("$1" == "all") ]];
#     then
#         source ./controlmine.conf
#         for r in ${BACKUP_DIR[@]}
#             do

# fi


#====Maint Tasks====#
# Reboot the remote node
if [[ ("$2" == "reboot") ]];
    then
        clear
        echo "WARNING! You are about to reboot the remote node!"
        read -e -p "Proceed? [y/N] : " START_UPGRADE

        if [[ ("$START_UPGRADE" == "y" || "$START_UPGRADE" == "Y") ]];
            then
                echo "Rebooting remote node..."
                ssh -q -t $CURRENT_USER@$SERVER "sudo reboot"
                exit 0
        fi
fi

#====Status Tasks====#
# Check the status of a remote node.
if [[ ("$2" == "status") ]];
    then
        clear
        echo "Node Status [$SERVER]:"
        echo "================================================="
        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli masternode status' $C_USER"
        echo "================================================="

        echo "MNSync Status [$SERVER]:"
        echo "================================================="
        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli mnsync status' $C_USER"
        echo "================================================="
        exit 0
fi

#====Install Tasks====#
if [[ ("$2" == "localinstall") ]];
    then
        clear
        echo "This process will install all build and runtime dependancies and will"
        echo "install $COIN_BASE from the upstream latest in src."
        read -e -p "Proceed? [y/N] : " START_LOCALINSTALL

        if [[ ("$START_LOCALINSTALL" == "y" || "$START_LOCALINSTALL" == "Y") ]];
            then
                if [[ ("$COIN_BASE" == "FGC") ]];
                    then
                        echo "     "
                        echo "============================================="
                        echo "Installing FantasyGold/FantasyGold-Core from src..."
                        echo "============================================="
                        echo "     "
                        mkdir -p $BUILD_DIR
                        cd $BUILD_DIR
                        git clone https://github.com/FantasyGold/FantasyGold-Core.git
                        ./autogen.sh
                        ./configure
                        make
                        sudo make install
                fi
                if [[ ("$COIN_BASE" == "AEG") ]];
                    then
                        echo "     "
                        echo "============================================="
                        echo "Installing AegeusCoin/aegeus from src..."
                        echo "============================================="
                        echo "     "
                        mkdir -p $BUILD_DIR
                        cd $BUILD_DIR
                        git clone https://github.com/AegeusCoin/aegeus.git
                        ./autogen.sh
                        ./configure
                        make
                        sudo make install                
                fi
            else
                echo "User aborted process."
                exit 1
        fi
fi

if [[ ("$2" == "upgradesrc") ]];
    then
        clear
        echo "WARNING! You are about to uninstall $COIN_BASE from the remote node!"
        echo "You are about to remove the existing package and upgrade to the latest in src."
        echo "This action will not remove your settings, nor will it install new users, set conf options, etc."
        echo "This process will only effect the core package, and will rebuild it from source."
        read -e -p "Proceed? [y/N] : " START_UPGRADE

        if [[ ("$START_UPGRADE" == "y" || "$START_UPGRADE" == "Y") ]];
            then
                if [[ ("$COIN_BASE" == "FGC") ]];
                    then
                        echo "     "
                        echo "============================================="
                        echo "Removing FantasyGold/FantasyGold-Core from specified node..."
                        echo "============================================="
                        echo "     "
                        echo "Stopping fantasygoldd service..."
                        ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl disable fantasygoldd && sudo systemctl stop fantasygoldd"
                        echo "Removing files..."
                        # ssh -q -t $CURRENT_USER@$SERVER "rm -rf /home/$CURRENT_USER/dev/FantasyGold-Core"
                        # ssh -q -t $CURRENT_USER@$SERVER "rm -rf /home/$CURRENT_USER/dev"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/fantasygold-cli"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/fantasygoldd"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/fantasygold-tx"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/test_fantasygold"
                        clear
                        echo "All existing files have been removed... Uninstall complete."
                        sleep 1

                        echo "     "
                        echo "============================================="
                        echo "Installing FantasyGold-Core from src..."
                        echo "============================================="
                        echo "     "
                        ssh -q -t $CURRENT_USER@$SERVER "mkdir -p $BUILD_DIR"
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR && git clone https://github.com/FantasyGold/FantasyGold-Core.git"
                        # git clone https://github.com/FantasyGold/FantasyGold-Core.git
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR && ./autogen.sh"
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR && ./configure"
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR && make"
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR && sudo make install"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl enable fantasygoldd && sudo systemctl start fantasygoldd"
                        echo "Upgrade process complete."
                fi
                if [[ ("$COIN_BASE" == "AEG") ]];
                  then
                        echo "     "
                        echo "============================================="
                        echo "Removing AegeusCoin/aegeus from specified node..."
                        echo "============================================="
                        echo "     "
                        echo "Stopping aegeusd service..."
                        ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl disable aegeusd && sudo systemctl stop aegeusd"
                        echo "Removing files..."
                        # ssh -q -t $CURRENT_USER@$SERVER "rm -rf /home/$CURRENT_USER/dev/FantasyGold-Core"
                        # ssh -q -t $CURRENT_USER@$SERVER "rm -rf /home/$CURRENT_USER/dev"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/aegeus-cli"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/aegeusd"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/aegeus-tx"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/test_aegeus"
                        clear
                        echo "All existing files have been removed... Uninstall complete."
                        sleep 1

                        echo "     "
                        echo "============================================="
                        echo "Installing AegeusCoin/aegeus from src..."
                        echo "============================================="
                        echo "     "
                        ssh -q -t $CURRENT_USER@$SERVER "mkdir -p $BUILD_DIR"
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR && git clone https://github.com/AegeusCoin/aegeus.git"
                        # git clone https://github.com/FantasyGold/FantasyGold-Core.git
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR/aegeus && ./autogen.sh"
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR/aegeus && ./configure"
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR/aegeus && make"
                        ssh -q -t $CURRENT_USER@$SERVER "cd $BUILD_DIR/aegeus && sudo make install"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl enable fantasygoldd && sudo systemctl start fantasygoldd"
                        echo "Upgrade process complete."
                fi
            else
                echo "User aborted process."
                exit 1
        fi
fi

if [[ ("$2" == "uninstall") ]];
    then
        clear
        read -e -p "WARNING! You are about to uninstall $COIN_BASE from the remote node. Continue? [y/N] : " UNINSTALL_Q_R

        if [[ ("$UNINSTALL_Q_R" == "y" || "$UNINSTALL_Q_R" == "Y") ]];
            then
                if [[ ("$COIN_BASE" == "FGC") ]];
                    then
                        echo "Stopping fantasygoldd service..."
                        ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl disable fantasygoldd && sudo systemctl stop fantasygoldd"
                        echo "Removing files..."
                        # ssh -q -t $CURRENT_USER@$SERVER "rm -rf /home/$CURRENT_USER/dev/FantasyGold-Core"
                        # ssh -q -t $CURRENT_USER@$SERVER "rm -rf /home/$CURRENT_USER/dev"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/fantasygold-cli"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/fantasygoldd"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/fantasygold-tx"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/test_fantasygold"
                        clear
                        echo "All existing files have been removed... Uninstall complete."
                        exit 0
                fi
                if [[ ("$COIN_BASE" == "AEG") ]];
                    then
                        echo "     "
                        echo "============================================="
                        echo "Removing AegeusCoin/aegeus from specified node..."
                        echo "============================================="
                        echo "     "
                        echo "Stopping aegeusd service..."
                        ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl disable aegeusd && sudo systemctl stop aegeusd"
                        echo "Removing files..."
                        # ssh -q -t $CURRENT_USER@$SERVER "rm -rf /home/$CURRENT_USER/dev/FantasyGold-Core"
                        # ssh -q -t $CURRENT_USER@$SERVER "rm -rf /home/$CURRENT_USER/dev"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/aegeus-cli"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/aegeusd"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/aegeus-tx"
                        ssh -q -t $CURRENT_USER@$SERVER "sudo rm /usr/local/bin/test_aegeus"
                        clear
                        echo "All existing files have been removed... Uninstall complete."
                        exit 0
                fi
            else
                echo "User aborted process."
                exit 1
        fi
fi

# If $2 is set to deps install dependancies
if [[ ("$2" == "deps") ]];
    then
        clear
        echo "User chose to install deps...."
        ssh -q -t $CURRENT_USER@$SERVER "sudo yum install wget git sudo nano unzip autoconf automake libtool gcc-c++ libdb4-devel libdb4 libdb4-cxx libdb4-cxx-devel db4-utils boost-devel openssl-devel miniupnpc bind-utils libevent-devel"
        exit 0
fi

# "Install" (or honestly just copy from fgcmaster) the precompiled binaries to the remote system
if [[ ("$2" == "install") ]];
    then
    if [[ ("$COIN_BASE" == "FGC") ]];
        then
            clear
            echo "User chose to install $COIN_BASE bins...."
            ssh -q -t $CURRENT_USER@$SERVER "rm -rf $TMP_DIR"
            ssh -q -t $CURRENT_USER@$SERVER "mkdir -p $TMP_DIR/pkg/usr/local/bin/"
            scp /usr/local/bin/fantasygold-cli $CURRENT_USER@$SERVER:$TMP_DIR/pkg/usr/local/bin/fantasygold-cli
            scp /usr/local/bin/fantasygoldd $CURRENT_USER@$SERVER:$TMP_DIR/pkg/usr/local/bin/fantasygoldd
            scp /usr/local/bin/fantasygold-tx $CURRENT_USER@$SERVER:$TMP_DIR/pkg/usr/local/bin/fantasygold-tx
            scp /usr/local/bin/test_fantasygold $CURRENT_USER@$SERVER:$TMP_DIR/pkg/usr/local/bin/test_fantasygold
            ssh -q -t $CURRENT_USER@$SERVER "sudo cp $TMP_DIR/pkg/usr/local/bin/fantasygold-cli /usr/local/bin/fantasygold-cli"
            ssh -q -t $CURRENT_USER@$SERVER "sudo cp $TMP_DIR/pkg/usr/local/bin/fantasygoldd /usr/local/bin/fantasygoldd"
            ssh -q -t $CURRENT_USER@$SERVER "sudo cp $TMP_DIR/pkg/usr/local/bin/fantasygold-tx /usr/local/bin/fantasygold-tx"
            ssh -q -t $CURRENT_USER@$SERVER "sudo cp $TMP_DIR/pkg/usr/local/bin/test_fantasygold /usr/local/bin/test_fantasygold"
            echo "Installation complete."
            exit 0
    fi
    if [[ ("$COIN_BASE" == "AEG") ]];
        then
            clear
            echo "User chose to install $COIN_BASE bins...."
            ssh -q -t $CURRENT_USER@$SERVER "rm -rf $TMP_DIR"
            ssh -q -t $CURRENT_USER@$SERVER "mkdir -p $TMP_DIR/pkg/usr/local/bin/"
            scp /usr/local/bin/aegeus-cli $CURRENT_USER@$SERVER:$TMP_DIR/pkg/usr/local/bin/aegeus-cli
            scp /usr/local/bin/aegeusd $CURRENT_USER@$SERVER:$TMP_DIR/pkg/usr/local/bin/aegeusd
            scp /usr/local/bin/aegeus-tx $CURRENT_USER@$SERVER:$TMP_DIR/pkg/usr/local/bin/aegeus-tx
            scp /usr/local/bin/test_aegeus $CURRENT_USER@$SERVER:$TMP_DIR/pkg/usr/local/bin/test_aegeus
            ssh -q -t $CURRENT_USER@$SERVER "sudo cp $TMP_DIR/pkg/usr/local/bin/aegeus-cli /usr/local/bin/aegeus-cli"
            ssh -q -t $CURRENT_USER@$SERVER "sudo cp $TMP_DIR/pkg/usr/local/bin/aegeusd /usr/local/bin/aegeusd"
            ssh -q -t $CURRENT_USER@$SERVER "sudo cp $TMP_DIR/pkg/usr/local/bin/aegeus-tx /usr/local/bin/aegeus-tx"
            ssh -q -t $CURRENT_USER@$SERVER "sudo cp $TMP_DIR/pkg/usr/local/bin/test_aegeus /usr/local/bin/test_aegeus"
            echo "Installation complete."
            exit 0
    fi
fi

# if [[ ("$2" == "masternode") ]];
#     then
#         clear
#         echo "User chose to compile the local masternode bins...."
#         source ./uninstall.sh
#         ssh -q -t $CURRENT_USER@$SERVER "mkdir /home/$CURRENT_USER/dev"
#         ssh -q -t $CURRENT_USER@$SERVER "cd /home/$CURRENT_USER/dev && git clone https://github.com/FantasyGold/FantasyGold-Core.git"
#         ssh -q -t $CURRENT_USER@$SERVER "cd /home/$CURRENT_USER/dev/FantasyGold-Core/ && ./autogen.sh"
#         ssh -q -t $CURRENT_USER@$SERVER "cd /home/$CURRENT_USER/dev/FantasyGold-Core/ && ./configure"
#         ssh -q -t $CURRENT_USER@$SERVER "cd /home/$CURRENT_USER/dev/FantasyGold-Core/ && make"
#         ssh -q -t $CURRENT_USER@$SERVER "cd /home/$CURRENT_USER/dev/FantasyGold-Core/ && sudo make install"
#         exit 0
# fi

if [[ ("$2" == "adopt") ]];
    then
        clear
        echo "User chose to adpot a new $COIN_BASE remote node...."
        # scp -q $CURRENT_USER@$n:/home/$CURRENT_USER/fsg_c/fantasygold.conf.old $TMP_DIR/$n/fantasygold.conf.old
        ssh -q -t $CURRENT_USER@$SERVER "mkdir -p $TMP_DIR"
        ssh -q -t $CURRENT_USER@$SERVER "sudo adduser -M -r $C_USER"
        RPCUSER=`ssh -q -t $CURRENT_USER@$SERVER "cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1"`
        RPCPASSWORD=`ssh -q -t $CURRENT_USER@$SERVER "cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1"`
        PUBLIC_IP=`ssh -q -t $CURRENT_USER@$SERVER "dig +short myip.opendns.com @resolver1.opendns.com"`
        INTERNAL_IP=`ssh -q -t $CURRENT_USER@$SERVER "hostname --ip-address"`

        read -e -p "Masternode Private Key [none]: " KEY

        if [[ ("$COIN_BASE" == "FGC") ]];
            then
                read -e -p "Choose tcp port for node [57810] : " NODEPORT_Q_R
                if [[ ( -z "$NODEPORT_Q_R" ) ]];
                    then
                        NODEPORT="57810"
                    else
                        NODEPORT=$NODEPORT_Q_R
                fi
        fi
        if [[ ("$COIN_BASE" == "AEG") ]];
            then
                read -e -p "Choose tcp port for node [29328] : " NODEPORT_Q_R
                    if [[ ( -z "$NODEPORT_Q_R" ) ]];
                        then
                            # NODEPORT="57810"
                            NODEPORT="29328"
                        else
                            NODEPORT=$NODEPORT_Q_R
                    fi
        fi
        # 
 
        if [[ ("$COIN_BASE" == "FGC") ]];
            then
ssh -q -t $CURRENT_USER@$SERVER "
cat > $TMP_DIR/fantasygoldd.service << EOL
[Unit]
Description=fantasygoldd
After=network.target
[Service]
Type=forking
User=$C_USER
WorkingDirectory=/home/$C_USER
ExecStart=/usr/local/bin/fantasygoldd -conf=/home/$C_USER/.fantasygold/fantasygold.conf -datadir=/home/$C_USER/.fantasygold
ExecStop=/usr/local/bin/fantasygold-cli -conf=/home/$C_USER/.fantasygold/fantasygold.conf -datadir=/home/$C_USER/.fantasygold stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOL
"

ssh -q -t $CURRENT_USER@$SERVER "touch $TMP_DIR/fantasygold.conf"
ssh -q -t $CURRENT_USER@$SERVER "
cat > $TMP_DIR/fantasygold.conf << EOL
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
externalip=${PUBLIC_IP}
bind=$INTERNAL_IP:$NODEPORT
masternodeaddr=${PUBLIC_IP}
masternodeprivkey=${KEY}
masternode=1
EOL
"

                ssh -q -t $CURRENT_USER@$SERVER "sudo mkdir -p /home/$C_USER/.fantasygold"
                ssh -q -t $CURRENT_USER@$SERVER "sudo chown -R $C_USER:$C_USER /home/$C_USER"
                ssh -q -t $CURRENT_USER@$SERVER "sudo mv $TMP_DIR/fantasygold.conf /home/$C_USER/.fantasygold/fantasygold.conf"
                ssh -q -t $CURRENT_USER@$SERVER "sudo chown -R $C_USER:$C_USER /home/$C_USER/.fantasygold"
                ssh -q -t $CURRENT_USER@$SERVER "sudo chmod 600 /home/$C_USER/.fantasygold/fantasygold.conf"

                ssh -q -t $CURRENT_USER@$SERVER "sudo mv $TMP_DIR/fantasygoldd.service /etc/systemd/system/fantasygoldd.service"
                ssh -q -t $CURRENT_USER@$SERVER "sudo chown root:root /etc/systemd/system/fantasygoldd.service"
                ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl daemon-reload"
                ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl enable fantasygoldd"
                ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl start fantasygoldd"
                ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl status fantasygoldd"
                clear
        fi

        if [[ ("$COIN_BASE" == "AEG") ]];
            then
ssh -q -t $CURRENT_USER@$SERVER "
cat > $TMP_DIR/aegeusd.service << EOL
[Unit]
Description=aegeusd
After=network.target
[Service]
Type=forking
User=$C_USER
WorkingDirectory=/home/$C_USER
ExecStart=/usr/local/bin/aegeusd -conf=/home/$C_USER/.aegeus/aegeus.conf -datadir=/home/$C_USER/.aegeus
ExecStop=/usr/local/bin/aegeus-cli -conf=/home/$C_USER/.aegeus/aegeus.conf -datadir=/home/$C_USER/.aegeus stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOL
"

ssh -q -t $CURRENT_USER@$SERVER "touch $TMP_DIR/aegeus.conf"
ssh -q -t $CURRENT_USER@$SERVER "
cat > $TMP_DIR/aegeus.conf << EOL
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
externalip=${PUBLIC_IP}
bind=$INTERNAL_IP:$NODEPORT
masternodeaddr=${PUBLIC_IP}
masternodeprivkey=${KEY}
masternode=1
EOL
"

                ssh -q -t $CURRENT_USER@$SERVER "sudo mkdir -p /home/$C_USER/.aegeus"
                ssh -q -t $CURRENT_USER@$SERVER "sudo chown -R $C_USER:$C_USER /home/$C_USER"
                ssh -q -t $CURRENT_USER@$SERVER "sudo mv $TMP_DIR/aegeus.conf /home/$C_USER/.aegeus/aegeus.conf"
                ssh -q -t $CURRENT_USER@$SERVER "sudo chown -R $C_USER:$C_USER /home/$C_USER/.aegeus"
                ssh -q -t $CURRENT_USER@$SERVER "sudo chmod 600 /home/$C_USER/.aegeus/aegeus.conf"

                ssh -q -t $CURRENT_USER@$SERVER "sudo mv $TMP_DIR/aegeusd.service /etc/systemd/system/aegeusd.service"
                ssh -q -t $CURRENT_USER@$SERVER "sudo chown root:root /etc/systemd/system/aegeusd.service"
                ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl daemon-reload"
                ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl enable aegeusd"
                ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl start aegeusd"
                ssh -q -t $CURRENT_USER@$SERVER "sudo systemctl status aegeusd"
                clear        
        fi

        echo "Your masternode is syncing. Please wait for this process to finish."
        echo "This can take up to a few hours. Do not close this window." && echo ""
        sleep 1

        if [[ ("$COIN_BASE" == "FGC") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                echo "waiting..."
                sleep 30
        fi
        if [[ ("$COIN_BASE" == "AEG") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                echo "waiting..."
                sleep 30
        fi    

        if [[ ("$COIN_BASE" == "FGC") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                echo "waiting..."
                sleep 30
        fi
        if [[ ("$COIN_BASE" == "AEG") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                echo "waiting..."
                sleep 30
        fi
        
        if [[ ("$COIN_BASE" == "FGC") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                echo "waiting..."
                sleep 30
        fi
        if [[ ("$COIN_BASE" == "AEG") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                echo "waiting..."
                sleep 30
        fi    
        
        if [[ ("$COIN_BASE" == "FGC") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                echo "waiting..."
                sleep 30
        fi
        if [[ ("$COIN_BASE" == "AEG") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                echo "waiting..."
                sleep 30
        fi    
        
        if [[ ("$COIN_BASE" == "FGC") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
        fi
        if [[ ("$COIN_BASE" == "AEG") ]];
            then
                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
        fi    
        echo "    "

        read -e -p "Does it appear it finished syncing yet? [y/N] : " SYNCED_Q_R

        if [[ ("$SYNCED_Q_R" == "y" || "$SYNCED_Q_R" == "Y") ]];
            then
                if [[ ("$COIN_BASE" == "FGC") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli masternode status' $C_USER"
                        sleep 5
                        echo "" && echo "Masternode setup completed." && echo ""
                        exit 0
                fi
                if [[ ("$COIN_BASE" == "AEG") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli masternode status' $C_USER"
                        sleep 5
                        echo "" && echo "Masternode setup completed." && echo ""
                        exit 0
                fi
            else
                if [[ ("$COIN_BASE" == "FGC") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                        echo "waiting..."
                        sleep 30
                fi
                if [[ ("$COIN_BASE" == "AEG") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                        echo "waiting..."
                        sleep 30
                fi    
        
                if [[ ("$COIN_BASE" == "FGC") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                        echo "waiting..."
                        sleep 30
                fi
                if [[ ("$COIN_BASE" == "AEG") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                        echo "waiting..."
                        sleep 30
                fi    

                if [[ ("$COIN_BASE" == "FGC") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                        echo "waiting..."
                        sleep 30
                fi
                if [[ ("$COIN_BASE" == "AEG") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                        echo "waiting..."
                        sleep 30
                fi    

                if [[ ("$COIN_BASE" == "FGC") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                        echo "waiting..."
                        sleep 30
                fi
                if [[ ("$COIN_BASE" == "AEG") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                        echo "waiting..."
                        sleep 30
                fi    

                if [[ ("$COIN_BASE" == "FGC") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                fi
                if [[ ("$COIN_BASE" == "AEG") ]];
                    then
                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                fi    

                read -e -p "Does it appear it finished syncing yet? [y/N] : " SYNCED1_Q_R

                if [[ ("$SYNCED1_Q_R" == "y" || "$SYNCED1_Q_R" == "Y") ]];
                    then
                        if [[ ("$COIN_BASE" == "FGC") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli masternode status' $C_USER"
                                sleep 5
                                echo "" && echo "Masternode setup completed." && echo ""
                                exit 0
                        fi
                        if [[ ("$COIN_BASE" == "AEG") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli masternode status' $C_USER"
                                sleep 5
                                echo "" && echo "Masternode setup completed." && echo ""
                                exit 0
                        fi
                    else
                        if [[ ("$COIN_BASE" == "FGC") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                                echo "waiting..."
                                sleep 30
                        fi
                        if [[ ("$COIN_BASE" == "AEG") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                                echo "waiting..."
                                sleep 30
                        fi    
                
                        if [[ ("$COIN_BASE" == "FGC") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                                echo "waiting..."
                                sleep 30
                        fi
                        if [[ ("$COIN_BASE" == "AEG") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                                echo "waiting..."
                                sleep 30
                        fi    

                        if [[ ("$COIN_BASE" == "FGC") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                                echo "waiting..."
                                sleep 30
                        fi
                        if [[ ("$COIN_BASE" == "AEG") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                                echo "waiting..."
                                sleep 30
                        fi    

                        if [[ ("$COIN_BASE" == "FGC") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                                echo "waiting..."
                                sleep 30
                        fi
                        if [[ ("$COIN_BASE" == "AEG") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                                echo "waiting..."
                                sleep 30
                        fi    

                        if [[ ("$COIN_BASE" == "FGC") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                        fi
                        if [[ ("$COIN_BASE" == "AEG") ]];
                            then
                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                        fi

                        read -e -p "Does it appear it finished syncing yet? [y/N] : " SYNCED2_Q_R

                        if [[ ("$SYNCED2_Q_R" == "y" || "$SYNCED2_Q_R" == "Y") ]];
                            then
                                if [[ ("$COIN_BASE" == "FGC") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli masternode status' $C_USER"
                                        sleep 5
                                        echo "" && echo "Masternode setup completed." && echo ""
                                        exit 0
                                fi
                                if [[ ("$COIN_BASE" == "AEG") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli masternode status' $C_USER"
                                        sleep 5
                                        echo "" && echo "Masternode setup completed." && echo ""
                                        exit 0
                                fi
                            else
                                if [[ ("$COIN_BASE" == "FGC") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                                        echo "waiting..."
                                        sleep 30
                                fi
                                if [[ ("$COIN_BASE" == "AEG") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                                        echo "waiting..."
                                        sleep 30
                                fi    
                        
                                if [[ ("$COIN_BASE" == "FGC") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                                        echo "waiting..."
                                        sleep 30
                                fi
                                if [[ ("$COIN_BASE" == "AEG") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                                        echo "waiting..."
                                        sleep 30
                                fi    

                                if [[ ("$COIN_BASE" == "FGC") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                                        echo "waiting..."
                                        sleep 30
                                fi
                                if [[ ("$COIN_BASE" == "AEG") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                                        echo "waiting..."
                                        sleep 30
                                fi    

                                if [[ ("$COIN_BASE" == "FGC") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                                        echo "waiting..."
                                        sleep 30
                                fi
                                if [[ ("$COIN_BASE" == "AEG") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                                        echo "waiting..."
                                        sleep 30
                                fi    

                                if [[ ("$COIN_BASE" == "FGC") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"
                                fi
                                if [[ ("$COIN_BASE" == "AEG") ]];
                                    then
                                        ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli startmasternode local false' $C_USER"
                                fi

                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli startmasternode local false' $C_USER"

                                read -e -p "Does it appear it finished syncing yet? [y/N] : " SYNCED3_Q_R

                                if [[ ("$SYNCED3_Q_R" == "y" || "$SYNCED3_Q_R" == "Y") ]];
                                    then
                                        if [[ ("$COIN_BASE" == "FGC") ]];
                                            then
                                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/fantasygold-cli masternode status' $C_USER"
                                                sleep 5
                                                echo "" && echo "Masternode setup completed." && echo ""
                                                exit 0
                                        fi
                                        if [[ ("$COIN_BASE" == "AEG") ]];
                                            then
                                                ssh -q -t $CURRENT_USER@$SERVER "sudo su -c '/usr/local/bin/aegeus-cli masternode status' $C_USER"
                                                sleep 5
                                                echo "" && echo "Masternode setup completed." && echo ""
                                                exit 0
                                        fi
                                    else
                                        echo "At this point this script has run down it's own timer. You can continue to watch it manually using the following:"
                                        ./controlmine.sh <node> status
                                        exit 0
                                fi
                        fi
                fi
        fi
fi



