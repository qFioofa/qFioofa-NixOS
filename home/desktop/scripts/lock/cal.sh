#!/usr/bin/env bash
while :; do
  @cal@ --color=always \
    | @awk@ 'NR==1{printf "\033[1;33m%s\033[0m\n",$0;next}
              NR==2{printf "\033[34m%s\033[0m\n",$0;next}
              {print}' \
    | @centerTop@
  @sleep@ 1800
done
