{ pkgs, ... }:
# Cisco AnyConnect VPN-клиент (SSL VPN). Проприетарный AnyConnect не собирается
# в nixpkgs — используем openconnect, совместимый с AnyConnect-серверами.
# Подключение: nm-applet (иконка сетей в трее) → VPN Connections → Add →
# тип "Cisco AnyConnect" → адрес сервера.
{
  # Плагин AnyConnect для NetworkManager — появляется как тип VPN в nm-applet
  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];

  # networkmanager-openconnect уже включает GNOME-панель настроек VPN
  # (withGnome = true) — она появится в установленном gnome-control-center.
  # CLI-версия клиента для отладки/скриптов:
  environment.systemPackages = [ pkgs.openconnect ];

  # TUN-модуль для VPN-туннеля (как в amnezia-vpn.nix)
  boot.kernelModules = [ "tun" ];
}