cask "flownet" do
  version "2026.02.0"
  sha256 "9b91a5dcc52ad033b6628d7834e0a89024bf1606557bc761d126fca7fb57862d"

  url "https://github.com/Se7enbrc/flownet/archive/refs/tags/#{version}.tar.gz"
  name "FlowNet"
  desc "AWDL suppression daemon for optimized WiFi performance"
  homepage "https://github.com/Se7enbrc/flownet"

  depends_on macos: ">= :ventura"
  depends_on formula: "swift"

  preflight do
    system_command "make",
                   args: ["-C", staged_path.join("flownet-#{version}")]
  end

  binary "#{staged_path}/flownet-#{version}/build/flownet"
  binary "#{staged_path}/flownet-#{version}/flowctl"

  postflight do
    plist_path = "/Library/LaunchDaemons/com.whaleyshire.flownet.plist"
    daemon_path = "/opt/homebrew/bin/flownet"
    log_path = "/var/log/flownet.log"

    plist_content = <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>com.whaleyshire.flownet</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{daemon_path}</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <dict>
              <key>SuccessfulExit</key>
              <false/>
          </dict>
          <key>ThrottleInterval</key>
          <integer>30</integer>
          <key>StandardOutPath</key>
          <string>#{log_path}</string>
          <key>StandardErrorPath</key>
          <string>#{log_path}</string>
          <key>UserName</key>
          <string>root</string>
          <key>ProcessType</key>
          <string>Background</string>
          <key>Nice</key>
          <integer>1</integer>
          <key>AbandonProcessGroup</key>
          <true/>
      </dict>
      </plist>
    PLIST

    File.write("/tmp/flownet.plist", plist_content)

    system_command "/usr/bin/sudo",
                   args: ["mv", "/tmp/flownet.plist", plist_path],
                   sudo: true

    system_command "/usr/bin/sudo",
                   args: ["chmod", "644", plist_path],
                   sudo: true

    system_command "/usr/bin/sudo",
                   args: ["chown", "root:wheel", plist_path],
                   sudo: true

    system_command "/usr/bin/sudo",
                   args: ["touch", log_path],
                   sudo: true

    system_command "/usr/bin/sudo",
                   args: ["launchctl", "bootstrap", "system", plist_path],
                   sudo: true
  end

  uninstall_preflight do
    system "/usr/bin/sudo /bin/launchctl bootout system/com.whaleyshire.flownet 2>/dev/null || true"
  end

  uninstall delete: "/Library/LaunchDaemons/com.whaleyshire.flownet.plist"

  caveats <<~EOS
    FlowNet is now running and will start automatically at boot.

    Check status:
      flowctl status

    View logs:
      flowctl logs
  EOS
end
