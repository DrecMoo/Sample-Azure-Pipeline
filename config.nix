{ config, pkgs, ... }:
#sudo nixos-rebuild switch
{
  imports =
    [
      # Include hardware scan results
      ./hardware-configuration.nix
    ];

  # Boot loader configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Enable VirtualBox Guest Additions
  virtualisation.virtualbox.guest.enable = true;

  # Root filesystem (adjust device path to match your system)
  #fileSystems."/" = {
  #  device = "/dev/sda1";
  #  fsType = "ext4";
  #};

  users.users.drecmoo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "vboxsf" ]; # Enables 'sudo' for the user
    initialHashedPassword = "$y$j9T$2SiuXxH6iFTzAuPXdYNZg.$YrStkpy.fScUWTEzNzuBnqRoCh.PNJDhNhiyJULTZy9";
  };

  # User account for running the Azure DevOps agent
  users.users.azureagent = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
  };

  #Security rules to enable rebuilds via DevOps pipeline
  security.sudo.extraRules = [
    {
      users = [ "azureagent" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/cp";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Service to apply configuration from pipeline
  systemd.services.nixos-apply-config = {
    description = "Apply NixOS Configuration from Pipeline";
    environment = {
      NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix";
    };
    serviceConfig = {
      Type = "exec";
      TimeoutStartSec = "10min";
      ExecStart = "${pkgs.writeShellScript "apply-config" ''
        set -e
        exec ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch
      ''}";
    };
  };

  # Networking
  networking.hostName = "azure-devops-agent";
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "America/Chicago";


  # System packages needed for Azure DevOps builds
  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    wget
    curl
    git

    # Build tools
    gcc
    gnumake
    cmake


    dotnet-sdk_8
    nodejs_20
    python3

    # Container tools
    docker
    docker-compose

    # Azure CLI
    azure-cli
    azure-cli-extensions.azure-devops

    # Terminal emulator
    alacritty

    # Other useful tools
    jq
    unzip
    zip

    # FHS environment for Azure DevOps agent
    (pkgs.buildFHSEnv {
      name = "azure-agent-env";
      targetPkgs = pkgs: with pkgs; [
        bash
        coreutils
        glibc
        icu
        krb5
        lttng-ust
        openssl
        zlib
        curl
        git
        dotnet-sdk_8
        nodejs_20
      ];
      runScript = "bash";
    })
  ];

  # Enable XFCE Desktop Environment
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm.enable = true;
  };

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # System auto-upgrade
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  
  # Enable Nix flakes (optional, for modern Nix features)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Azure DevOps Agent systemd service
  systemd.services.azuredevops-agent = {
    description = "Azure DevOps Agent";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "azureagent";
      WorkingDirectory = "/home/azureagent/azagent";
      ExecStart = "/home/azureagent/azagent/run.sh";
      Restart = "always";
      RestartSec = "10s";
      NoNewPrivileges = false;
    };
    environment = {
      AGENT_ALLOW_RUNASROOT = "1";
      VSTS_AGENT_IGNORE_SANDBOX = "1";
  };

  # System state version
  system.stateVersion = "24.05";

  # Azure DevOps Agent Setup Instructions:
  # 1. Switch to azureagent user: sudo su - azureagent
  # 2. Download agent: wget https://vstsagentpackage.azureedge.net/agent/3.236.1/vsts-agent-linux-x64-3.236.1.tar.gz
  # 3. Create directory: mkdir -p ~/azagent && cd ~/azagent
  # 4. Extract: tar zxvf ~/vsts-agent-linux-x64-3.236.1.tar.gz
  # 5. Configure: ./config.sh (requires PAT token, organization URL, agent pool)
  # 6. Install service: sudo ./svc.sh install azureagent
  # 7. Start service: sudo ./svc.sh start
}
