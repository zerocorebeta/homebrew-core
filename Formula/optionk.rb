class Optionk < Formula
  desc "OptionK CLI and server application"
  homepage "https://github.com/zerocorebeta/OptionK"
  url "https://api.github.com/repos/zerocorebeta/Option-K/tarball/v1.0.0"
  sha256 "0a5759197d322ff29025a907b9894dc0e83461e2ad5bb76a19efb9ea50b043d7"
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
    ohai "To finalize the setup, please follow these steps:"
    ohai "1. Create the configuration directory:"
    ohai "   mkdir -p ~/.optionk"
    ohai "2. Create the configuration file:"
    ohai "   touch ~/.optionk/config.ini"
    ohai "3. Add the default configuration content to the file."
    ohai "   You can find the sample configuration file at:"
    ohai "   https://github.com/zerocorebeta/Option-K/blob/master/config.ini"
    ohai "   Copy the content from the sample file and paste it into ~/.optionk/config.ini"
    ohai "4. Open ~/.optionk/config.ini and add your API key to the file."
    ohai "   Replace the placeholder 'YOUR_API_KEY_HERE' with your actual API key."

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