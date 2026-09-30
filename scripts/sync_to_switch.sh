#!/bin/bash

DIR=$(dirname $0)
. $DIR/utils.sh

echo_r 'rsync -avzhcqPe "ssh -p 2332 gaoweize@101.6.96.190 -t ssh -p 22" ${DIR}/../  root@10.0.0.30:/root/gwz/code/netcacheplus'
# echo_r 'rsync -avzhcqPe "ssh -p 2332 gaoweize@101.6.96.190 -t ssh -p 22" ${DIR}/../  root@10.0.0.30:/root/gwz/code/netcacheplus'