#!/bin/sh
cat ../rom/VERSION > version.txt
scp *.tzx *.tap *.bin vexed4.alioth.net:/var/www/vhosts/spectrum/www/downloads
scp *.bin vexed4.alioth.net:/home/tnfsd/tnfsroot/firmware
scp version.txt vexed4.alioth.net:/home/tnfsd/tnfsroot/firmware

