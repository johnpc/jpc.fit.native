Feature: Quotes Tab
  As a signed-in user
  I want to view motivational quotes
  So that I can stay inspired

  Scenario: View quotes
    Given I am signed in
    When I tap the Quotes tab
    Then I should see motivational content
