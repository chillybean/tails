@product
Feature: Installing and running Flatpak apps in Tails
  As a Tails user
  I may want to install and run software not shipped in Tails or Debian
  And keep them up-to-date

  Scenario: GNOME Software does not have the Debian plugin
    Given I have the build manifest for the image under test
    Then Debian package gnome-software-plugin-deb is not installed

  @check_tor_leaks
  Scenario: Installing, starting and uninstalling a Flatpak
    Given I have started Tails with the Flatpak feature from a USB drive with a persistent partition enabled and logged in and the network is connected
    When I start GNOME Software
    And I install Signal Desktop using GNOME Software
    Then the org.signal.Signal Flatpak is installed after at most 300 seconds
    When I start the org.signal.Signal Flatpak
    Then the org.signal.Signal Flatpak is running
    Given I kill the org.signal.Signal Flatpak
    And I go to the main screen of GNOME Software
    When I uninstall Signal Desktop using GNOME Software
    Then the org.signal.Signal Flatpak is uninstalled after at most 60 seconds
