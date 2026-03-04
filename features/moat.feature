@product
Feature: Asking for Tor bridge settings based on your location
  As a Tails user
  I want to easily obtain bridge settings suitable for my location

  Background:
    Given a computer
    And I set Tails to run with real Tor network
    And I start the computer
    And the computer boots Tails
    And I log in to a new session
    And all notifications have disappeared
    When the network is plugged
    Then the Tor Connection Assistant autostarts

  @supports_real_tor
  Scenario: Automatic mode when asking for bridge settings in Tor Connection
    When I configure Tor Connection to ask for bridge settings based on my location
    Then I wait for a long time until Tor is ready
    And available upgrades have been checked
