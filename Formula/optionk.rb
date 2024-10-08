class Optionk < Formula
  desc "OptionK CLI and server application"
  homepage "https://github.com/zerocorebeta/OptionK"
  url "https://api.github.com/repos/zerocorebeta/Option-K/tarball/v1.0.4"
  sha256 "3d279d1e673c486749e2f7a622908e00bd48f790b361aea5cde1f10a6dfdcccd"
  version "1.0.4"
  license "MIT"

  depends_on "python@3.12"

  def install
    venv = libexec/"venv"
    ENV.prepend_path "PATH", Formula["python@3.12"].opt_libexec/"bin"
    system "python3", "-m", "venv", venv

    # Upgrade pip, setuptools, and wheel in the virtualenv
    system venv/"bin/pip", "install", "--upgrade", "pip", "setuptools", "wheel"
    
    # Install the package and its dependencies
    system venv/"bin/pip", "install", "-r", "requirements.txt"
    system venv/"bin/pip", "install", "-e", "."
    
    # Copy the client and server scripts to libexec
    libexec.install "client/opk.py"
    libexec.install "server/opk-server.py"
    
    # Set correct permissions for the Python scripts
    chmod 0755, libexec/"opk.py"
    chmod 0755, libexec/"opk-server.py"
    
    # Create wrapper scripts
    (bin/"opk").write <<~EOS
      #!/bin/bash
      export PATH="#{venv}/bin:$PATH"
      export PYTHONPATH="#{libexec}:#{venv}/lib/python3.12/site-packages"
      exec "#{venv}/bin/python3" "#{libexec}/opk.py" "$@"
    EOS

    (bin/"opk-server").write <<~EOS
      #!/bin/bash
      export PATH="#{venv}/bin:$PATH"
      export PYTHONPATH="#{libexec}:#{venv}/lib/python3.12/site-packages"
      exec "#{venv}/bin/python3" "#{libexec}/opk-server.py" "$@"
    EOS

    # Make the wrapper scripts executable
    chmod 0755, bin/"opk"
    chmod 0755, bin/"opk-server"

    # Modify and install the optionk_alias.sh script
    optionk_alias_content = <<~EOS
      optionk() {
          local query="$BUFFER"
          local result=$(#{opt_bin}/opk "$query" --quick)
          BUFFER="$result"
          zle end-of-line
      }

      zle -N optionk

    EOS
    (share/"opk_alias.sh").write(optionk_alias_content)

    # Install the plist file for macOS
    if OS.mac?
      (prefix/"homebrew.mxcl.optionk.plist").write plist_contents
    end
  end

  def plist_contents
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>/bin/bash</string>
          <string>-c</string>
          <string>#{opt_bin}/opk-server</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/opk-server.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/opk-server.log</string>
      </dict>
      </plist>
    EOS
  end
    
  def post_install
    ohai "Installation Complete!"
    puts "Edit the `~/.config/optionk/config.ini` file to configure the AI backend"
    puts "check https://github.com/zerocorebeta/Option-K?tab=readme-ov-file#configuration for detailed information on this"

    ohai "Shell Integration"
    puts "To enable the optionk command `opk`, add the following lines to your shell configuration file (.zshrc, .bashrc, etc.):"
    puts "  source #{share}/opk_alias.sh"
    puts "  bindkey '˚' optionk  # Note: Option+K mapped to quick suggestion, you may change it"

    if OS.mac?
      ohai "LaunchAgent Setup"
      puts "To enable the OptionK server to start automatically, run the following command:"
      puts "  brew services start optionk"
    end
  end

  test do
    system bin/"opk", "--help"
    system bin/"opk-server", "--help"
  end
end