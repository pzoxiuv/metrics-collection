#!/bin/bash

sudo apt update && sudo apt install -y vim git screen python3 docker.io pigz
echo "if [ -n \$MYPID ] && [ "\$TERM" != "dumb" ] && [ -z "\$STY" ]; then screen -dRRS \$MYPID; fi" | tee -a ~/.bashrc
echo "AcceptEnv MYPID" | sudo tee -a /etc/ssh/sshd_config
sudo service sshd restart
