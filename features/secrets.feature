@product
Feature: Using Secrets

  Scenario: I can easily access kdbx files in /home/amnesia/Persistent
    Given I have started Tails without network from a USB drive with a persistent partition and stopped at Tails Greeter's login screen
    And I enable persistence
    And I write a file "/home/amnesia/Persistent/Passwords.kdbx" with contents ""
    And I change ownership of file "/home/amnesia/Persistent/Passwords.kdbx" to "amnesia:"
    And I log in to a new session
    When I start "Secrets" via GNOME Activities Overview
    Then Secrets tries to open "/home/amnesia/Persistent/Passwords.kdbx"
