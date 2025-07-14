@product
Feature: Using Webtunnel Tor bridges
  As a Tails user
  I want to circumvent censorship of Tor by using Webtunnel bridges
  And avoid connecting directly to the Tor Network

  Background:
    Given a computer
    And I set Tails to run with real Tor network
    And I start the computer
    And the computer boots Tails
    And I log in to a new session
    When the network is plugged
    Then the Tor Connection Assistant autostarts

  @supports_real_tor @check_tor_leaks
  Scenario: Configuring webtunnel with QR code
        When I configure some webtunnel bridges from a QR code in the Tor Connection Assistant in hide mode

  Scenario: Typing webtunnel pluggable transports directly
    When I configure some webtunnel bridges in the Tor Connection Assistant in hide mode without connecting
    Then I can click the "Connect to Tor" button
