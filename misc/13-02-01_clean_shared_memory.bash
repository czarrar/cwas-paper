#!/bin/bash

# This script will cycle through each of the 48 nodes on gelert
# It actually doesn't work so for now manually deleting...TODO automation

for i in $( count -digits 1 1 48 ); do
    echo "qrsh -l hostname=node$i"
        qrsh -l hostname=node$i
    echo "rm /dev/shm/*"
        rm /dev/shm/*
    exit
done
