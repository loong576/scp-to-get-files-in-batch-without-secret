#!/bin/bash

IP=172.27.34.85
USER=root
PASSWD=monitor123!
DEST1=myfile_4.txt
DEST2=myfile_5.txt
DEST3=dir
LOCAL_PATH=/tmp/files
DEST_PATH=/root/product

$HOME/scp/scp.sh   $IP $USER $PASSWD  $DEST1 $DEST2 $DEST3 $LOCAL_PATH  $DEST_PATH
