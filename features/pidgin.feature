#19040
@product @fragile
Feature: Chatting anonymously using Pidgin
  As a Tails user
  when I chat using Pidgin
  I should be able to persist my Pidgin configuration
  And AppArmor should prevent Pidgin from doing dangerous things
  And all Internet traffic should flow only through Tor

  Scenario: Make sure Pidgin's D-Bus interface is blocked
    Given I have started Tails from DVD without network and logged in
    When I start "Pidgin Internet Messenger" via GNOME Activities Overview
    Then I see Pidgin's account manager window
    And Pidgin's D-Bus interface is not available

  @check_tor_leaks
  Scenario: Chatting with some friend over XMPP
    Given I have started Tails from DVD and logged in and the network is connected
    When I start "Pidgin Internet Messenger" via GNOME Activities Overview
    Then I see Pidgin's account manager window
    When I create my XMPP account
    And I close Pidgin's account manager window
    Then Pidgin automatically enables my XMPP account
    Given my XMPP friend goes online
    When I start a conversation with my friend
    And I say something to my friend
    Then I receive a response from my friend

  @check_tor_leaks
  Scenario: Using a persistent Pidgin configuration
    Given I have started Tails without network from a USB drive with a persistent partition enabled and logged in
    And the network is plugged
    And Tor is ready
    And available upgrades have been checked
    And all notifications have disappeared
    When I start "Pidgin Internet Messenger" via GNOME Activities Overview
    Then I see Pidgin's account manager window
    When I create my XMPP account
    And I close Pidgin's account manager window
    Then Pidgin automatically enables my XMPP account
    When I close Pidgin
    And I take note of the configured Pidgin accounts
    And I shutdown Tails and wait for the computer to power off
    Given a computer
    And I start Tails from USB drive "__internal" and I login with persistence enabled
    And Pidgin has the expected persistent accounts configured
    When I start "Pidgin Internet Messenger" via GNOME Activities Overview
    Then Pidgin automatically enables my XMPP account
    # Exercise Pidgin AppArmor profile with persistence enabled.
    # This should really be in dedicated scenarios, but it would be
    # too costly to set up the virtual USB drive with persistence more
    # than once in this feature.
    Given I start monitoring the AppArmor log of "/usr/bin/pidgin"
    Then I cannot add a certificate from the "/home/amnesia/.gnupg" directory to Pidgin
    And AppArmor has denied "/usr/bin/pidgin" from opening "/home/amnesia/.gnupg/test.crt"
    When I close Pidgin's certificate import failure dialog
    And I close Pidgin's certificate manager
    Given I restart monitoring the AppArmor log of "/usr/bin/pidgin"
    Then I cannot add a certificate from the "/live/persistence/TailsData_unlocked/gnupg" directory to Pidgin
    And AppArmor has denied "/usr/bin/pidgin" from opening "/live/persistence/TailsData_unlocked/gnupg/test.crt"
    When I close Pidgin's certificate import failure dialog
    And I close Pidgin's certificate manager
    Then I can add a certificate from the "/home/amnesia" directory to Pidgin
