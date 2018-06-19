# ControlMine
*ControlMine: A basic remote crypto-miner command and control system. (Built for CentOS 7)*

## This software is highly experimental!
If you are at all a novice Linux or Fantasy Gold Coin user you probably shouldn't be trying to use this yet until an official version 1 is released.

This documentation will be updated as development progresses. 

These scripts depend heavily on ssh. It's highly recommended that the remote ssh user has the following conditions met for optimal ControlMine performance:
1. Set sudo to operate without a password. Either use visudo to change wheel from:
```
%wheel ALL=(ALL) ALL
```
...to:
```
%wheel ALL=(ALL) NOPASSWD: ALL
```
2. Install an ssh key on the remote node and use keyfiles instead of passwords to connect.
See https://wiki.archlinux.org/index.php/SSH_keys for more information on how to generate and use ssh keys.

## Usage
Syntax:
```
$ ./controlmine.sh <servername> <option>
```

## Options
To use ControlMine, you'll feed it 2 options: the remote server name and the action you wish to perform. All available options are outlined as follows:
```
status          Show the current status of a remote node
reboot          Reboot the remote node
deps            Install all build and runtime dependancy packages on the remote node
install         Using the precompiled binaries located on the master control node, install precompiled binaries to the remote node
localinstall    Build and Deploy the main ControlMine scripts to your chosen local master control node
adopt           Adopt a new remote node that has been correctly prepared using 'deps' and 'install' first
upgradesrc      Upgrade the FantasyGold-core package on the remote node from upstream source.
uninstall       Uninstall FantasyGold-core from the remote node
```

## Examples

### To deploy your master control node:
*(On the new system that will be your master control node...)*
1. Download these scripts and cd ino that directory:
```
$ git clone https://github.com/dhtseany/FGC-ControlMine-CentOS7.git
$ cd FGC-ControlMine-CentOS7/
```
2. Run the automated master control install script:
```
$ ./controlmine.sh localhost localinstall
```

### To adopt a new remote node that has established ssh access:
*From here all instructions assume that you're now working from the master control node*

1. Download these scripts and cd ino that directory:
```
$ git clone https://github.com/dhtseany/FGC-ControlMine-CentOS7.git
$ cd FGC-ControlMine-CentOS7/
```
2. First, we install the dependancies on the remote system:
```
$ ./controlmine.sh newserver1 deps
```
3. Next, we install the precompiled binaries from our master control node to the new remote node:
```
$ ./controlmine.sh newserver1 install
```
4. Finally, we adopt the new node:
```
$ /.controlmine.sh newserver1 adopt
```

### To query the status of a remote node after it's been adopted, use:
```
$ ./controlmine.sh newserver1 status
```

### To reboot a remote node:
```
$ ./controlmine.sh newserver1 reboot
```