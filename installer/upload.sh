#!/bin/sh
cat ../rom/VERSION > version.txt
scp *.tzx *.tap *.bin vexed5.alioth.net:/var/www/vhosts/spectrum.alioth.net/www/downloads
scp *.bin vexed4.alioth.net:/home/tnfsd/tnfsroot/firmware
scp version.txt vexed4.alioth.net:/home/tnfsd/tnfsroot/firmware

