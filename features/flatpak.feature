@product
Feature: Installing and running Flatpak apps in Tails
  As a Tails user
  I may want to install and run software not shipped in Tails or Debian
  And keep them up-to-date

  Scenario: GNOME Software does not have the Debian plugin
    Given I have the build manifest for the image under test
    Then Debian package gnome-software-plugin-deb is not installed
