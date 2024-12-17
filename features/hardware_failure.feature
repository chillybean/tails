@product
Feature: Hardware failures
  In order to update my failing hardware before I lose data
  As a Tails user
  I want to be warned about hardware failures

  Scenario Outline: Alerting about disk read failures before reaching the Welcome Screen
    Given a computer
    And I start the computer from DVD with network unplugged
    When Tails detects disk read failures on the <device>
    Then I see a disk failure message on the splash screen
    Examples:
      | device |
      | SquashFS |
      | boot device |
      | boot device with a target error |

  @doc
  Scenario Outline: Alerting about disk read failures in GNOME
    Given a computer
    And I have started Tails without network from a USB drive with a persistent partition enabled and logged in
    When Tails detects disk read failures on the <device>
    Then I see a disk failure message
    Then I can open the hardware failure documentation from the disk failure message
    Examples:
      | device |
      | SquashFS |
      | boot device |
      | boot device with a target error |

  Scenario Outline: Case B: GPT backup corruption with a persistent partition
    Given I have started Tails without network from a USB drive with a persistent partition and stopped at Tails Greeter's login screen
    And I corrupt the boot device's GPT backup <thing>
    And I power off the computer
    When I start the computer
    Then the computer boots Tails
    When I log in to a new session
    And all notifications have disappeared
    Then I am recommended to migrate to a new USB stick due to partitioning errors
    Examples:
    | thing           |
    | header          |
    | partition table |

  Scenario: Case 3: Partitioning corruption without a persistent partition
    Given a computer
    And I set Tails to boot with options "test_gpt_corruption=gpt_backup,gpt_backup_table"
    And I temporarily create a 7200 MiB disk named "temp"
    And I plug USB drive "temp"
    And I write the Tails USB image to disk "temp"
    When I start Tails from USB drive "temp" with network unplugged
    Then Tails is running from USB drive "temp"
    And the Greeter forbids creating a persistent partition
    When I log in to a new session
    And all notifications have disappeared
    Then I am recommended to reinstall Tails due to partitioning errors

  Scenario: Case A: The disk GUID was not changed
    Given a computer
    And I set Tails to boot with options "test_gpt_corruption=guid"
    And I temporarily create a 7200 MiB disk named "temp"
    And I plug USB drive "temp"
    And I write the Tails USB image to disk "temp"
    When I start Tails from USB drive "temp" with network unplugged
    Then Tails is running from USB drive "temp"
    And the Greeter recommends reinstalling Tails due to partitioning errors
    And the Greeter forbids starting Tails
    And the Greeter forbids all settings but language
