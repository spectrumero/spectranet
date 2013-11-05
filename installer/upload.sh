#!/bin/sh
svn up
echo `svn info .|grep -m 1 Rev|cut -d " " -f 2` > version.txt
scp *.tzx *.tap *.bin providence.alioth.net:/var/www/vhosts/spectrum/www/downloads
scp *.bin vexed4.alioth.net:/home/tnfsd/tnfsroot/firmware
scp version.txt vexed4.alioth.net:/home/tnfsd/tnfsroot/firmware

