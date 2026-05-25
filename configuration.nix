{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
  ];

  # --- 1. Ядро и системные параметры ---
  # Zen-ядро дает лучшую отзывчивость (low latency) в играх и Niri
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- 2. Специфичные настройки ASUS Zephyrus ---
  services.asusd = {
    enable = true;
    enableUserService = true;
  };
  # Управление режимами графики (Integrated/Hybrid/VFIO)
  services.supergfxctl.enable = true;
  # Оптимизация питания
  services.power-profiles-daemon.enable = true;

  # --- 3. Видеодрайверы и гибридная графика ---
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Обязательно для Steam/Proton
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # Экономит заряд, отключая GPU
    open = false; # 1660 Ti лучше работает на закрытом драйвере
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Шины для G14 2021 (Ryzen 4800HS + GTX 1660 Ti)
      amdgpuBusId = "PCI:4:0:0"; 
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # --- 4. Композитор Niri и Wayland ---
  programs.niri.enable = true;
  
  # Окружение для правильной работы Nvidia в Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    # Переменные для запуска Niri на Nvidia (если возникнут проблемы с отрисовкой)
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # --- 5. Steam и Гейминг ---
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    # Авто-настройка Proton
    extraPackages = with pkgs; [
      mangohud # Оверлей FPS
      gamemode # Приоритет CPU для игр
    ];
  };
  programs.gamemode.enable = true;

  # --- 6. Звук (Pipewire) ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # --- 7. Пакеты для системы ---
  environment.systemPackages = with pkgs; [
    # Интерфейс
    fuzzel        # Лаунчер (аналог rofi)
    waybar        # Статус-бар
    alacritty     # Терминал (GPU ускорение)
    mako          # Уведомления
    swaybg        # Обои
    
    # Утилиты для ASUS и GPU
    brightnessctl # Яркость
    pciutils      # lspci
    nvtopPackages.full # Мониторинг GPU (Amd + Nvidia)
    asusctl       # Управление профилями вентиляторов в CLI
  ];

  # --- 8. Оптимизация системы ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  networking.networkmanager.enable = true;
  system.stateVersion = "25.11"; 
}
