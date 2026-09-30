#!/bin/bash

DIR=$(dirname $0)
. $DIR/utils.sh

for i in {1..2}
do
    # echo_r 'ssh -p 2332 gaoweize@101.6.96.190 -t ssh -p 22 gaoweize@10.0.0.${i} "[ -d /home/gaoweize/code/ ] || mkdir /home/gaoweize/code/"'
	echo_r 'rsync -avzhcqPe "ssh -p 2332 gaoweize@101.6.96.190 -t ssh -p 22" ${DIR}/../  gaoweize@10.0.0.${i}:/home/gaoweize/code/netcacheplus'
    echo_r "ssh -p 2332 gaoweize@101.6.96.190 -t \"ssh -p 22 gaoweize@10.0.0.${i} 'cd /home/gaoweize/code/netcacheplus/host/ && make clean && make' \""
done