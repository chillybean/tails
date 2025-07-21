@product
Feature: Using WebTunnel Tor bridges
  As a Tails user
  I want to circumvent censorship of Tor by using WebTunnel bridges
  And avoid connecting directly to the Tor Network

  Background:
    Given a computer
    And I set Tails to run with real Tor network
    And I start the computer
    And the computer boots Tails
    # Let's be sure WebTunnel bridges work with a clock East of UTC
    And I bump the system time with "+8 hours +15 minutes"
    And I log in to a new session
    When the network is plugged
    Then the Tor Connection Assistant autostarts

  @supports_real_tor @check_tor_leaks
  Scenario: Configuring WebTunnel with QR code
        When I configure some webtunnel bridges from a QR code in the Tor Connection Assistant in hide mode

  Scenario: Typing WebTunnel pluggable transports directly
    When I configure some webtunnel bridges in the Tor Connection Assistant in hide mode without connecting
    Then I can click the "Connect to Tor" button
