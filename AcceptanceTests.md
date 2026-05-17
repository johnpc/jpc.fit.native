# Acceptance Tests

## Feature: User Login

```gherkin
Feature: User Login
  As a user
  I want to sign in to the app
  So that I can access my calorie tracking data

  Scenario: Successful login
    Given the app is launched
    When I enter valid credentials
    And I tap the sign in button
    Then I should see the Calories tab
    And the tab bar should show all 5 tabs
```

## Feature: Calories Tab

```gherkin
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
```

## Feature: Weight Tab

```gherkin
Feature: Weight Tab
  As a signed-in user
  I want to track my weight
  So that I can monitor my progress

  Scenario: View weight tab
    Given I am signed in
    When I tap the Weight tab
    Then I should see the weight tracking view
```

## Feature: Stats Tab

```gherkin
Feature: Stats Tab
  As a signed-in user
  I want to view my calorie history
  So that I can see weekly trends

  Scenario: View stats
    Given I am signed in
    When I tap the Stats tab
    Then I should see my weekly stats
```

## Feature: Quotes Tab

```gherkin
Feature: Quotes Tab
  As a signed-in user
  I want to view motivational quotes
  So that I can stay inspired

  Scenario: View quotes
    Given I am signed in
    When I tap the Quotes tab
    Then I should see motivational content
```

## Feature: Settings Tab

```gherkin
Feature: Settings Tab
  As a signed-in user
  I want to manage my account settings
  So that I can configure quick adds and sign out

  Scenario: View settings
    Given I am signed in
    When I tap the Settings tab
    Then I should see the settings view
    And I should see a sign out button
```
