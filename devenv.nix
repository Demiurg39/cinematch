{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  project_ref = config.secretspec.secrets.SUPABASE_PROJECT_REF;
in {
  # https://devenv.sh/basics/
  env.QT_QPA_PLATFORM = "xcb";

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    claude-code
    nodejs
    chromium
    secretspec
  ];

  android = {
    enable = true;
    flutter = {
      enable = true;
      package = pkgs.flutter341;
    };
    platforms.version = ["34" "35" "36"];
    systemImageTypes = ["google_apis_playstore"];
    abis = ["x86_64"];
    cmake.version = ["3.22.1"];
    cmdLineTools.version = "11.0";
    tools.version = "26.1.1";
    buildTools.version = ["34.0.0" "35.0.0" "36.0.0"];
    emulator.enable = true;
    sources.enable = false;
    systemImages.enable = true;
    ndk.enable = true;
    ndk.version = ["28.2.13676358"];
    googleAPIs.enable = true;
    extraLicenses = [
      "android-sdk-license"
      "android-sdk-preview-license"
    ];
  };

  claude.code = {
    enable = true;
    mcpServers = {
      devenv = {
        type = "stdio";
        command = "devenv";
        args = ["mcp"];
        env = {
          DEVENV_ROOT = config.devenv.root;
        };
      };
      supabase = {
        type = "http";
        url = "https://mcp.supabase.com/mcp?project_ref=${project_ref}&features=docs%2Cdatabase%2Cdevelopment%2Cstorage";
      };
      dart = {
        type = "stdio";
        command = "dart";
        args = ["mcp-server"];
      };
      browsermcp = {
        type = "stdio";
        command = "npx";
        args = [
          "-y" # Automatically accept package installation
          "@browsermcp/mcp@latest"
        ];
        env.CHROME_PATH = "${pkgs.chromium}/bin/chromium";
      };
    };
  };

  dotenv.enable = true;

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts = {
    emu.exec = ''
      LD_LIBRARY_PATH="" emulator @cinematch-emu -no-snapshot-load
    '';
    run-android.exec = ''
      flutter run -d cinematch-emu
    '';
    run.exec = ''
      flutter run
    '';
    build.exec = ''
      flutter build apk
    '';
  };

  # https://devenv.sh/basics/
  # enterShell = ''
  #   hello         # Run scripts directly
  #   git --version # Use packages
  # '';

  # https://devenv.sh/tasks/
  # tasks = {
  # "myproj:setup".exec = "mytool build";
  # "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  # enterTest = ''
  #   echo "Running tests"
  #   git --version | grep --color=auto "${pkgs.git.version}"
  # '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
