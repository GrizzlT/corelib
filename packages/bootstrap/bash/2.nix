core:
core.mkPackage {
  function = {
    std,
    fetchurl,
    runCommand,
    mkMinimalPackage,
    mescc-tools-extra,
    tinycc-mes,
    gnumake,
    gnupatch,
    coreutils,
    bash_2_05,
    ...
  }:
    let
    inherit (std.strings) concatMapStringsSep makeBinPath;

    name = "bash";
    version = "2.05b";

    src = fetchurl {
      url = "https://ftpmirror.gnu.org/gnu/bash/bash-${version}.tar.gz";
      sha256 = "1r1z2qdw3rz668nxrzwa14vk2zcn00hw7mpjn384picck49d80xs";
    };

    # Thanks to the live-bootstrap project!
    # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/bash-2.05b/bash-2.05b.kaem
    liveBootstrap = "https://github.com/fosslinux/live-bootstrap/raw/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/bash-2.05b";

    main_mk = fetchurl {
      url = "${liveBootstrap}/mk/main.mk";
      sha256 = "0hj29q3pq3370p18sxkpvv9flb7yvx2fs96xxlxqlwa8lkimd0j4";
    };

    common_mk = fetchurl {
      url = "${liveBootstrap}/mk/common.mk";
      sha256 = "09rigxxf85p2ybnq248sai1gdx95yykc8jmwi4yjx389zh09mcr8";
    };

    builtins_mk = fetchurl {
      url = "${liveBootstrap}/mk/builtins.mk";
      sha256 = "0939dy5by1xhfmsjj6w63nlgk509fjrhpb2crics3dpcv7prl8lj";
    };

    patches = [
      # mes libc does not have locale support
      (fetchurl {
        url = "${liveBootstrap}/patches/mes-libc.patch";
        sha256 = "0zksdjf6zbb3p4hqg6plq631y76hhhgab7kdvf7cnpk8bcykn12z";
      })
      # int name, namelen; is wrong for mes libc, it is char* name, so we modify tinycc
      # to reflect this.
      (fetchurl {
        url = "${liveBootstrap}/patches/tinycc.patch";
        sha256 = "042d2kr4a8klazk1hlvphxr6frn4mr53k957aq3apf6lbvrjgcj2";
      })
      # add ifdef's for features we don't want
      (fetchurl {
        url = "${liveBootstrap}/patches/missing-defines.patch";
        sha256 = "1q0k1kj5mrvjkqqly7ki5575a5b3hy1ywnmvhrln318yh67qnkj4";
      })
      # mes libc + setting locale = not worky
      (fetchurl {
        url = "${liveBootstrap}/patches/locale.patch";
        sha256 = "1p1q1slhafsgj8x4k0dpn9h6ryq5fwfx7dicbbxhldbw7zvnnbx9";
      })
      # We do not have /dev at this stage of the bootstrap, including /dev/tty
      (fetchurl {
        url = "${liveBootstrap}/patches/dev-tty.patch";
        sha256 = "1315slv5f7ziajqyxg4jlyanf1xwd06xw14y6pq7xpm3jzjk55j9";
      })
    ];
  in
    runCommand.onHost "${name}-${version}"
    {
      tools = [
        tinycc-mes.onBuildForHost.compiler
        gnumake.onBuild
        gnupatch.onBuild
        coreutils.onBuild
      ];

      public.runCommand = name: env: buildCommand:
        mkMinimalPackage.onHost {
          inherit name;
          version = "";

          drv = {
            builder = "${bash_2_05.onBuild}/bin/bash";
            args = [
              "-e"
              (builtins.toFile "bash-builder.sh" ''
                export CONFIG_SHELL=$SHELL

                # Normalize the NIX_BUILD_CORES variable. The value might be 0, which
                # means that we're supposed to try and auto-detect the number of
                # available CPU cores at run-time. We don't have nproc to detect the
                # number of available CPU cores so default to 1 if not set.
                NIX_BUILD_CORES="''${NIX_BUILD_CORES:-1}"
                if [ $NIX_BUILD_CORES -le 0 ]; then
                  NIX_BUILD_CORES=1
                fi
                export NIX_BUILD_CORES

                bash -eux $buildCommandPath
              '')
            ];
            inherit buildCommand;
            passAsFile = [ "buildCommand" ];

            SHELL = "${bash_2_05.onBuild}/bin/bash";
            PATH = makeBinPath (
              (env.tools or [ ])
              ++ [
                bash_2_05.onBuild
                coreutils.onBuild
                # provides untar, ungz, and unbz2
                mescc-tools-extra.onBuild
              ]
            );
          } // (removeAttrs env [ "tools" "public" ]);
          public = env.public or {};
        };
    }
    ''
      # Unpack
      ungz --file ${src} --output bash.tar
      untar --file bash.tar
      rm bash.tar
      cd bash-${version}

      # Patch
      ${concatMapStringsSep "\n" (f: "patch -Np0 -i ${f}") patches}

      # Configure
      cp ${main_mk} Makefile
      cp ${builtins_mk} builtins/Makefile
      cp ${common_mk} common.mk
      touch config.h
      touch include/version.h
      touch include/pipesize.h

      # Build
      make \
        CC="tcc -B ${tinycc-mes.onBuildForHost.libs}/lib" \
        mkbuiltins
      cd builtins
      make \
        CC="tcc -B ${tinycc-mes.onBuildForHost.libs}/lib" \
        libbuiltins.a
      cd ..
      make CC="tcc -B ${tinycc-mes.onBuildForHost.libs}/lib"

      # Install
      install -D bash ''${out}/bin/bash
      ln -s bash ''${out}/bin/sh
    '';

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib) std;
    inherit (pkgs.self) tinycc-mes gnupatch gnumake coreutils bash_2_05;
    inherit (pkgs.stage0) runCommand mkMinimalPackage mescc-tools-extra;

    fetchurl = import ../../stage0-posix/bootstrap-fetchurl.nix;
  };
}

