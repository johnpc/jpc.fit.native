Feature: Stats Tab
  As a signed-in user
  I want to view my calorie history
  So that I can see weekly trends

  Scenario: View stats
    Given I am signed in
    When I tap the Stats tab
    Then I should see my weekly stats
