Feature: Calories Tab
  As a signed-in user
  I want to track my daily food intake
  So that I can manage my calorie budget

  Scenario: View today's food list
    Given I am signed in
    And I am on the Calories tab
    Then I should see the date navigation
    And I should see the remaining calories section

  Scenario: Navigate to previous day
    Given I am signed in
    And I am on the Calories tab
    When I tap the back button
    Then the date should change to yesterday
