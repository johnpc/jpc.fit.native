Feature: Weight Tab
  As a signed-in user
  I want to track my weight
  So that I can monitor my progress

  Scenario: View weight tab
    Given I am signed in
    When I tap the Weight tab
    Then I should see "BMI"
    And I should see "BMI Range for Your Height"

  @demo-data
  Scenario: Save a new weight
    Given I am signed in
    When I tap the Weight tab
    And I tap the "Edit Weight" button
    And I enter "185" in the prompt and save
    Then I should see "185 lbs"
