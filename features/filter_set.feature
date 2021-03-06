Feature: Filter set

  As a MAdeK user
  I want to organize automatically generated relations of resources
  So that I can track resources related to specific topics

  # TODO sollte im @jsbrowser laufen 
  @firefox
  Scenario: Create a filter set
   Given I am signed-in as "Normin"
    When I go to a search result page
     And I use some filters
     And I use the create filter set option
     And I provide a title
     And I submit
    Then I am getting redirected to the new filter set
    And I can see the provided title and the used filter settings

  # TODO sollte im @jsbrowser laufen 
  @firefox 
  Scenario: Edit a filter set
   Given I am signed-in as "Normin"
    When I open a filter set
     And I edit the filter set settings
     And I change the settings for that filter set
     And I save these changes
    Then I am getting redirected to the updated filter set
    And I can see the provided title and the used filter settings

  @firefox 
  Scenario: Edit the meta-data of a filter set
    Given I am signed-in as "Normin"
    When I open a filter set
    And I click on the link "Weitere Aktionen"
    And I click on the link "Metadaten editieren"
    And I am on the edit page of the resource
    And I click on "Speichern" 
    Then I can see "Die Änderungen wurden gespeichert."


