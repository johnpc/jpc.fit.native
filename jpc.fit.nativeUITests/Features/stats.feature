Feature: Stats Tab
  As a signed-in user
  I want to view my calorie history
  So that I can see weekly trends

  Scenario: View stats
    Given I am signed in
    When I tap the Stats tab
    Then I should see "1 lb of fat ≈ 3500 calories"
    And I should see the "Previous 7 days" button

  @demo-data
  Scenario: Streak counts every tracked day including today
    Given I am signed in
    When I tap the Stats tab
    Then I should see "Your streak is 13 days"
