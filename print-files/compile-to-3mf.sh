#!/bin/bash

for file in */data*.scad
do
    colorscad.sh -i "$file" -o "${file%.scad}.3mf" -f
done
