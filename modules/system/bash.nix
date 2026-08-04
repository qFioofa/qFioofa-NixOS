{ pkgs, ... }:
{
  # На NixOS нет /bin/bash (есть только /bin/sh), поэтому скрипты с шебангом
  # #!/bin/bash (или #!/usr/bin/python и т.п.) падают с "no such file or
  # directory". envfs монтирует /bin и /usr/bin как FUSE-фс, который резолвит
  # любой исполняемый файл из PATH — так работают и абсолютные шебанги, и
  # привычный #!/usr/bin/env bash, для bash и любого другого интерпретатора.
  services.envfs.enable = true;

  # Гарантируем, что сам bash присутствует в системном PATH.
  environment.systemPackages = [ pkgs.bashInteractive ];
}
