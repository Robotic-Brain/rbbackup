Feature: Print version information via Commandline
    In order to see the currently running version
    As a user
    There should be a way to show version information

    Scenario Outline: Only version argument
        Given there is an argument "<arg>"
         When I run trough a terminal
         Then Stdout should contain "version"
          And Stdout should contain "rbBackup"
          And Stdout should contain the actual version
          And the exit code should be 0

         Examples:
            | arg       |
            | -V        |
            | --version |
