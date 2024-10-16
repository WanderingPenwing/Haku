{
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    ./sd-image.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  # ! Need a trusted user for deploy-rs.
  nix.settings.trusted-users = ["@wheel"];
  system.stateVersion = "23.11";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  sdImage = {
    # bzip2 compression takes loads of time with emulation, skip it. Enable this if youre low on space.
    compressImage = false;
    imageName = "zero2.img";

    extraFirmwareConfig = {
      # Give up VRAM for more Free System Memory
      # - Disable camera which automatically reserves 128MB VRAM
      start_x = 0;
      # - Reduce allocation of VRAM to 16MB minimum for non-rotated (32MB for rotated)
      gpu_mem = 16;
    };
  };

  # Keep this to make sure wifi works
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [pkgs.raspberrypiWirelessFirmware];

  hardware.deviceTree = {
      enable = true;
      overlays = [{
          name = "dpi24";
          dtsText = ''
/dts-v1/;

/ {
	compatible = "brcm,bcm2708";

	fragment@0 {
		target = <0xffffffff>;

		__overlay__ {
			pinctrl-names = "default";
			pinctrl-0 = <0x01>;
		};
	};

	fragment@1 {
		target = <0xffffffff>;

		__overlay__ {

			dpi24_pins {
				brcm,pins = <0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e 0x0f 0x10 0x11 0x14 0x15 0x16 0x17 0x18 0x19 0x1a 0x1b>;
				brcm,function = <0x06>;
				brcm,pull = <0x00>;
				linux,phandle = <0x01>;
				phandle = <0x01>;
			};
		};
	};

	__symbols__ {
		dpi24_pins = "/fragment@1/__overlay__/dpi24_pins";
	};

	__fixups__ {
		leds = "/fragment@0:target:0";
		gpio = "/fragment@1:target:0";
	};

	__local_fixups__ {

		fragment@0 {

			__overlay__ {
				pinctrl-0 = <0x00>;
			};
		};
	};
};
          '';
      }];
  };

  boot = {
    # TODO doesnt work
    # kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;

    initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage" "fbtft" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;

      raspberryPi.firmwareConfig = ''
        disable_overscan=1
        gpu_mem_256=128
        gpu_mem_512=256
    
        # Enable GPI Case for Video Display via GPIO
        display_rotate=0
        overscan_left=0
        overscan_right=0
        overscan_top=0
        overscan_bottom=0
        framebuffer_width=640
        framebuffer_height=480
        enable_dpi_lcd=1
        display_default_lcd=1
        dpi_group=2
        dpi_mode=87
        dpi_output_format=0x00016
        hdmi_timings=640 0 1 1 20 480 0 1 1 2 0 0 0 60 0 19200000 1
      '';
    };

    # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
    # See: https://github.com/NixOS/nixpkgs/issues/254807
    swraid.enable = lib.mkForce false;

    kernelParams = [
    	"hello=there"
    ];
  };

  networking = {
  	hostName = "haku";
    interfaces."wlan0".useDHCP = true;
    wireless = {
      enable = true;
      interfaces = ["wlan0"];
      # ! Change the following to connect to your own network
      networks = {
        "Le Ninternet" = {
          psk = "XcTsS9mnz2ePwE7dps";
        };
        "Calcifer" = {
          psk = "HowlsMoving";
        };
      };
    };
  };

  # Enable OpenSSH out of the box.
  services.sshd.enable = true;

  # NTP time sync.
  services.timesyncd.enable = true;

  # ! Change the following configuration
  users.users.penwing = {
    isNormalUser = true;
    home = "/home/penwing";
    description = "Me";
    extraGroups = ["wheel" "networkmanager" "video" "media"];
    # ! Be sure to put your own public key here
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/SQbXjL6O2zjKFdybiMLu7Imc10IGrTMUnRtIxf0jJ nicolas.pinson31@gmail.com"];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = (with pkgs; [
    # CLIs
    starship # shell more pretty
    git # code versioning
    bottom # task manager
    micro # text editor
    fastfetch
    yazi

    #screen
    fbida # fbi to display image on screen
    fbterm

    #test
    libraspberrypi
    raspberrypi-eeprom

    dtc
  ]);
  
  # ! Be sure to change the autologinUser.
  services.getty.autologinUser = "penwing";
}
