Feature: Settings Tab
  As a signed-in user
  I want to manage my account settings
  So that I can configure quick adds and sign out

  Scenario: View settings
    Given I am signed in
    When I tap the Settings tab
    Then I should see the settings view
    And I should see a sign out button
