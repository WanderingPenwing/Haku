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
/plugin/;

/{
	compatible = "brcm,bcm2835";

	// There is no DPI driver module, but we need a platform device
	// node (that doesnt already use pinctrl) to hang the pinctrl
	// reference on - leds will do

	fragment@0 {
		target = <&fb>;
		__overlay__ {
			pinctrl-names = "default";
			pinctrl-0 = <&dpi24_pins>;
		};
	};

	fragment@1 {
		target = <&vc4>;
		__overlay__ {
			pinctrl-names = "default";
			pinctrl-0 = <&dpi24_pins>;
		};
	};

	fragment@2 {
		target = <&gpio>;
		__overlay__ {
			dpi24_pins: dpi24_pins {
				brcm,pins = <0 1 2 3 4 5 6 7 8 9 10 11
					     12 13 14 15 16 17 18 19 20
					     21 22 23 24 25 26 27>;
				brcm,function = <6>; /* alt2 */
				brcm,pull = <0>; /* no pull */
			};
		};
	};

	fragment@3 {
	    target = <&dpi>;
	    __overlay__ {
	        status = "okay";
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
