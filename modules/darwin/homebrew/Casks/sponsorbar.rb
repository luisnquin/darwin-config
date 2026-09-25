cask "sponsorbar" do
  version "1.0.16,17"
  sha256 "66c16c2374bb0e62069908bc90a68eba13d41b3ff50e6b853001b6837ca1f0e4"

  url "https://assets.sponsorbar.io/releases/macos/SponsorBar-#{version.csv.first}.dmg?build=#{version.csv.second}"
  name "SponsorBar"
  desc "Show paid sponsor messages in the macOS menu bar"
  homepage "https://sponsorbar.io/"

  auto_updates true
  depends_on macos: :sonoma

  app "SponsorBar.app"

  zap trash: [
    "~/Library/Application Support/SponsorBar",
    "~/Library/Preferences/com.kickbot.sponsorbar.plist",
  ]
end
