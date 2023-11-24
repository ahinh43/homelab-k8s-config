#!/usr/bin/env bash

# Labels nodes with the desired disk configuration

set -x
nodes=( 
  kubework01.labs.ahinh.me 
  kubework02.labs.ahinh.me 
  kubework03.labs.ahinh.me
)

for node in ${nodes[@]}; do
  kubectl label node $node node.longhorn.io/create-default-disk="config"  
  kubectl annotate node $node node.longhorn.io/default-disks-config='[{ "name":"default", "path":"/var/lib/longhorn", "allowScheduling":true }]'
done