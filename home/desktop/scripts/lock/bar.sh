#!/usr/bin/env bash
@awk@ -v p="$1" -v w="$2" -v c="$3" 'BEGIN{
  f=int(p*w/100+0.5); if(f>w)f=w; if(f<0)f=0;
  s="\033[" c "m"; for(i=0;i<f;i++) s=s"█";
  s=s"\033[90m"; for(i=f;i<w;i++) s=s"░";
  printf "%s\033[0m", s;
}'
