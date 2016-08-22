Feature: Test cosul agent process failure
  # Tested case with this Feature:
  #   - consul agent death on the alien4cloud leader
  #   - former leader becoming leader again
  #   - consul agent death on the alien4cloud backup

  Background:
    Given I am authenticated with "ADMIN" role
     And I upload the archive "tosca-normative-types-1.0.0-SNAPSHOT"
     And I upload the archive "samples"
     And I create an application "ALIEN" with a Compute and a JDK nodes
     And I upload a plugin
     And I setup an orchestrator "orchestrator" with a location "test-location"
     And I Set a unique location policy to "Mount doom orchestrator"/"Thark location" for all nodes
    #When I deploy it


  Scenario: The consul agent on the Alien4Cloud leader compute fails
      ## OK
    When I shutdown the consul agent on the alien4cloud leader instance
     And I wait for 10 seconds before continuing the test
    Then alien4cloud should be available
     And I should be able to access the application "ALIEN"
     And the alien4cloud backup instance should be the new leader

    ## restart the consul agent and make sure the alien instance is a backup
    When I restart the previously shutdown consul agent
    And I wait for 10 seconds before continuing the test
    Then this instance should be the backup

    ## repeat the first test, to validate that after being downgraded to slave, an instance can still be promoted as leader
    When I shutdown the consul agent on the alien4cloud leader instance
    And I wait for 10 seconds before continuing the test
    Then alien4cloud should be available
    And I should be able to access the application "ALIEN"
    And the alien4cloud backup instance should be the new leader

  ## OK
  Scenario: The consul agent on the Alien4Cloud backup compute fails
    When I shutdown the consul agent on the alien4cloud backup instance
     And I wait for 10 seconds before continuing the test
    Then alien4cloud should be available
     And I should be able to access the application "ALIEN"
     And the alien4cloud leader instance should still be the leader
