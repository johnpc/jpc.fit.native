Feature: Settings Tab
  As a signed-in user
  I want to manage my account settings
  So that I can configure quick adds and sign out

  Scenario: View settings
    Given I am signed in
    When I tap the Settings tab
    Then I should see the "New Quick Add" button
    And I should see the "Sign Out" button

  Scenario: Sign out returns to the sign-in screen
    Given I am signed in
    When I tap the Settings tab
    And I tap the "Sign Out" button
    Then I should see the sign-in screen
