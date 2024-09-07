class OptionK < Formula
  include Language::Python::Virtualenv

  desc "Option-K CLI and server application"
  homepage "https://example.com"  # Replace with your application's homepage
  url "https://github.com/yourusername/option-k/archive/refs/tags/v0.1.tar.gz"  # Replace with the correct URL
  sha256 "abc123..."  # Replace with the SHA256 hash of your tarball
  license "MIT"

  depends_on "python@3.9"

  def install
    # Install the virtual environment
    virtualenv_install_with_resources

    # Install Python scripts
    bin.install "client/option-k-cli.py" => "option-k-cli"
    bin.install "server/option-k-server.py" => "option-k-server"

    # Install .plist file
    plist_path = buildpath/"scripts/option_k_plist.plist"
    plist_content = plist_path.read
    plist_content.gsub!("{PYTHON_PATH}", "#{opt_bin}/python3")
    plist_content.gsub!("{SCRIPT_PATH}", "#{opt_bin}/option-k-server")
    (prefix/"option_k_plist.plist").write plist_content

    # Install alias script template
    (bin/"option_k_alias_template.sh").write IO.read("scripts/option_k_alias.sh")
  end

  def post_install
    # Create the ~/.option-k directory if it doesn't exist
    option_k_dir = Pathname.new(File.expand_path("~/.option-k"))
    option_k_dir.mkpath unless option_k_dir.exist?

    # Move the config file to ~/.option-k/
    config_file = var/"option-k/config.ini"
    config_file.rename(option_k_dir/"config.ini") if config_file.exist?

    # Replace placeholders in the alias script with the actual install path
    install_path = opt_prefix.to_s
    alias_script_content = (bin/"option_k_alias_template.sh").read
    alias_script_content.gsub!("{INSTALL_PATH}", install_path)

    # Save the processed alias script
    (bin/"option_k_alias.sh").write(alias_script_content)

    # Install zsh alias
    zshrc_path = File.expand_path("~/.zshrc")
    alias_script_path = bin/"option_k_alias.sh"
    unless File.readlines(zshrc_path).grep(/source #{alias_script_path}/).any?
      system "echo 'source #{alias_script_path}' >> #{zshrc_path}"
    end
  end

  test do
    system "#{bin}/option-k-cli", "--help"
    system "#{bin}/option-k-server", "--help"
  end
end