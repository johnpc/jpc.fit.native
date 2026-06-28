Feature: User Login
  As a user
  I want to sign in to the app
  So that I can access my calorie tracking data

  Scenario: Successful login
    Given the app is launched
    When I sign in with valid credentials
    Then I should see the Calories tab
    And the tab bar should show all 5 tabs
