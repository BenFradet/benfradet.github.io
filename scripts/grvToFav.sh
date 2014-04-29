#!/bin/bash

while getopts e:s: option;
do
    case "${option}" 
    in
        e) EMAIL=${OPTARG};;
        s) SIZE=${OPTARG};;
    esac
done

URL=$(python scripts/getHash.py -e $EMAIL -s $SIZE)
wget $URL -O /tmp/favicon.png

pngtopnm -mix /tmp/favicon.png > tmp_logo.pnm

pnmscale -xsize=32 -ysize=32 ./tmp_logo.pnm > tmp_logo32.ppm
pnmscale -xsize=16 -ysize=16 ./tmp_logo.pnm > tmp_logo16.ppm

pnmquant 256 tmp_logo32.ppm > tmp_logo32x32.ppm
pnmquant 256 tmp_logo16.ppm > tmp_logo16x16.ppm

ppmtowinicon -output favicon.ico tmp_logo16x16.ppm tmp_logo32x32.ppm

rm -f tmp_logo*

cp favicon.ico _site/favicon.ico
