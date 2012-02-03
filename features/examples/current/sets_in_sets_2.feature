Feature: Sets in Sets II

  Background: Load the example data and personas
	Given I have set up the world
      And personas are loaded

  # https://www.pivotaltracker.com/story/show/23825307
  @committed @javascript
  Scenario: Preview of content and relationships of a set in the grid view
    Given I am "Normin"
     When I view a grid of these sets
      And I examine my "Ausstellungen" sets more closely
     Then I see relationships for this set
      And I see how many media entries that are viewable for me in this set
      And I see how many sets that are viewable for me in this set
      And I see how many sets that are viewable for me are parents of this set

  # https://www.pivotaltracker.com/story/show/22394303
  @committed @javascript
  Scenario: Choosing which contexts are valid for a set
   Given I am "Adam"
     And a context called "Landschaftsvisualisierung" exists
     And a context called "Zett" exists
     And a context called "Games" exists
     And a set called "Landschaften" that has the context "Landschaftsvisualisierung"
     And a set called "Zett" that has the context "Zett"
     And a set called "Zett über Landschaften" that has the context "Games"
     And the set called "Zett über Landschaften" is child of "Landschaften" and "Zett"
     And I can edit the set "Zett über Landschaften"
    When I view the set "Zett über Landschaften"
    Then I see the available contexts "Landschaftsvisualisierung" and "Zett"
     And I see some text explaining the consequences of assigning contexts to a set
    When I assign the context "Zett" to the set "Zett über Landschaften"
    Then the set "Zett über Landschaften" has the context "Zett"
    When I assign the context "Landschaftsvisualisierung" to the set "Zett über Landschaften"
    Then the set "Zett über Landschaften" has the context "Landschaftsvisualisierung"
     And the set still has the context called "Games"

  # https://www.pivotaltracker.com/story/show/22464659
  @committed @javascript
  Scenario: Viewing which contexts a set could have
   Given I am "Adam"
     And a context called "Landschaftsvisualisierung" exists
     And a context called "Zett" exists
     And a context called "Games" exists
     And a set called "Landschaften" that has the context "Landschaftsvisualisierung"
     And a set called "Zett" that has the context "Zett"
     And a set called "Zett über Landschaften" that has the context "Games"
     And the set called "Zett über Landschaften" is child of "Landschaften" and "Zett"
    When I view the set "Zett über Landschaften"
    Then I can choose to see more details about the context "Zett"
     And I can choose to see more details about the context "Landschaftsvisualisierung"
     And I can choose to see more details about the context "Games"

  # https://www.pivotaltracker.com/story/show/23825857
  @glossary @committed
  Scenario: Top-level set
    Given a few sets
     When a set has no parents
     Then it is a top-level set

  # https://www.pivotaltracker.com/story/show/22576523
  # https://www.pivotaltracker.com/story/show/23800945
  Scenario: Viewing a context
    Given a context
     When I look at a page describing this context
     Then the page's look is consistent with the rest of the application
      And I see all the keys that can be used in this context
      And I see all the values those keys can have
      And I see an abstract of the most assigned values from media entries using this context

  # https://www.pivotaltracker.com/story/show/23825857
  Scenario: Switch between all sets and main sets on the page 'my sets'
    Given a few sets
     When I view a list of my sets
     Then I see a list of my top-level sets
      And I can switch to a list of all my sets
     When I view a list of all my sets
     Then I see all my sets
