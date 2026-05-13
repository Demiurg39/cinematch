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
      socraticode = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "socraticode"
        ];
        env = {
          QDRANT_MODE = "external";
          QDRANT_URL = "http://localhost:6333";
          OLLAMA_MODE = "external";
          OLLAMA_BASE_URL = "http://localhost:11434";
        };
      };
    };
  };

  processes = {
    qdrant = {
      exec = lib.getExe pkgs.qdrant;
      ready.http.get = {
        port = 6333;
        path = "/healthz";
      };
    };
    ollama = {
      exec = "${lib.getExe pkgs.ollama-cuda} serve";
      ready.http.get = {
        port = 11434;
        path = "/";
      };
    };
    ollama-model-setup = {
      exec = ''
        # Check if the model is already present to avoid redundant pulls
        if ! ${lib.getExe pkgs.ollama-cuda} list | grep -q "nomic-embed-text"; then
          echo "📥 Pulling nomic-embed-text model..."
          ${lib.getExe pkgs.ollama-cuda} pull nomic-embed-text
        else
          echo "✅ Model nomic-embed-text is already available."
        fi
      '';
      after = ["devenv:processes:ollama"];
      ready.exec = "${lib.getExe pkgs.ollama-cuda} list | grep -q 'nomic-embed-text'";
      restart.on = "never";
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
