Feature: Weight Tab
  As a signed-in user
  I want to track my weight
  So that I can monitor my progress

  Scenario: View weight tab
    Given I am signed in
    When I tap the Weight tab
    Then I should see the weight tracking view
