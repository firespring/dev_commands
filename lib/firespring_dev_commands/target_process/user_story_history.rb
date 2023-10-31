module Dev
  class TargetProcess
    # Class containing user story information
    class UserStoryHistory
      # The resource type for the api endpoint
      RESOURCE_TYPE = 'UserStoryHistory'.freeze

      # The api path for user story requests
      PATH = '/UserStoryHistories'.freeze

      attr_accessor :type, :id, :name







=begin
  "ResourceType": "UserStoryHistory",
  "EntityType": {
    "ResourceType": "EntityType",
    "Id": 4,
    "Name": "UserStory"
  },
  "Id": 179691,
  "SourceEntityId": 74558,
  "Date": "/Date(1692735862810-0500)/",
  "DateTo": "/Date(1692735862810-0500)/",
  "Modification": "Update",
  "OriginatorId": null,
  "EventId": null,
  "ModificationContext": null,
  "InitialEstimate": 0.0,
  "IsChangedInitialEstimate": false,
  "Effort": 2.0,
  "IsChangedEffort": false,
  "EffortCompleted": 0.0,
  "IsChangedEffortCompleted": false,
  "EffortToDo": 2.0,
  "IsChangedEffortToDo": false,
  "TimeSpent": 0.0,
  "IsChangedTimeSpent": false,
  "TimeRemain": 0.0,
  "IsChangedTimeRemain": false,
  "PlannedStartDate": null,
  "IsChangedPlannedStartDate": false,
  "PlannedEndDate": null,
  "IsChangedPlannedEndDate": false,
  "Name": "Fix Rake client:php:security:audit",
  "IsChangedName": false,
  "Description": "<div>The local security audit for client-php fails since it uses a service that is no longer available. https&#58;&#47;&#47;security.symfony.com provides the following message&#44;</div>\r\n\n<pre>&quot;This service is not available anymore&#44; see https&#58;&#47;&#47;github.com&#47;fabpot&#47;local-php-security-checker for an Open-Source alternative.&quot;</pre>\r\n\n<div> \r\n<div>The security audit for Concourse was updated by ID&#58; 70271 to use local-php-security-checker but those changes were not carried over to the local rake task. The rake task should be updated to use the supported security checker.  Verify that security audit on code pipeline is correctly using this as well</div>\r\n\n<div> </div>\r\n\n<div> </div>\r\n</div>\r\n",
  "IsChangedDescription": false,
  "StartDate": "/Date(1692735847000-0500)/",
  "IsChangedStartDate": false,
  "EndDate": "/Date(1692735862000-0500)/",
  "IsChangedEndDate": true,
  "CreateDate": "/Date(1631282568000-0500)/",
  "IsChangedCreateDate": false,
  "ModifyDate": "/Date(1692735862000-0500)/",
  "IsChangedModifyDate": true,
  "LastCommentDate": null,
  "IsChangedLastCommentDate": false,
  "NumericPriority": 63993.0,
  "IsChangedNumericPriority": false,
  "IsChangedProject": false,
  "IsChangedFeature": false,
  "IsChangedBuild": false,
  "IsChangedRelease": false,
  "IsChangedIteration": false,
  "IsChangedTeam": false,
  "IsChangedWorkflowTeam": false,
  "IsChangedTeamIteration": false,
  "IsChangedPriority": false,
  "IsChangedEntityState": false,
  "IsChangedTeamState": false,
  "IsChangedEntityType": false,
  "IsChangedLastEditor": false,
  "IsChangedOwner": false,
  "IsChangedLastCommentedUser": false,
  "Project": {
    "ResourceType": "Project",
    "Id": 217,
    "Name": "St Baldricks"
  },
  "Feature": null,
  "Build": null,
  "Release": null,
  "Iteration": null,
  "WorkflowTeam": {
    "ResourceType": "Team",
    "Id": 20750,
    "Name": "SBF QA",
    "EmojiIcon": null
  },
  "Team": {
    "ResourceType": "Team",
    "Id": 20750,
    "Name": "SBF QA",
    "EmojiIcon": null
  },
  "TeamIteration": null,
  "Priority": {
    "ResourceType": "Priority",
    "Id": 5,
    "Name": "Nice To Have",
    "Importance": 5
  },
  "TeamState": {
    "ResourceType": "EntityState",
    "Id": 367,
    "Name": "Returned",
    "NumericPriority": 3.0
  },
  "EntityState": {
    "ResourceType": "EntityState",
    "Id": 69,
    "Name": "Returned",
    "NumericPriority": 9.5
  },
  "LastEditor": {
    "ResourceType": "GeneralUser",
    "Id": 25,
    "FirstName": "Tony",
    "LastName": "Wilbrand",
    "Login": "tony.wilbrand",
    "FullName": "Tony Wilbrand"
  },
  "Owner": {
    "ResourceType": "GeneralUser",
    "Id": 23,
    "FirstName": "Val",
    "LastName": "Stehlik",
    "Login": "val.stehlik",
    "FullName": "Val Stehlik"
  },
  "LastCommentedUser": null,
  "CurrentUserStory": {
    "ResourceType": "UserStory",
    "Id": 74558,
    "Name": "Fix Rake client:php:security:audit"
  },
  "Modifier": {
    "ResourceType": "GeneralUser",
    "Id": 25,
    "FirstName": "Tony",
    "LastName": "Wilbrand",
    "Login": "tony.wilbrand",
    "FullName": "Tony Wilbrand"
  },
  "PreviousHistoryRecord": {
    "ResourceType": "UserStoryHistory",
    "Id": 179690,
    "Name": "Fix Rake client:php:security:audit"
  }
=end











      def initialize(data)
        puts JSON.pretty_generate(data)
        @id = data['Id']
        @type = data['ResourceType']
        @name = data['Name']
        #@description = data['Description']
        #@state = data['EntityState']['Name'] if data['EntityState']
        #@project = Project.new(data['Project']) if data['Project']
        #@owner = User.new(data['Owner']) if data['Owner']
        #@creator = User.new(data['Creator']) if data['Creator']
        #@release = Release.new(data['Release']) if data['Release']
        #@team = Team.new(data['Team']) if data['Team']
        #@start_date = parse_time(data['StartDate'])
        #@end_date = parse_time(data['EndDate'])
        #@create_date = parse_time(data['CreateDate'])
        #@modify_date = parse_time(data['ModifyDate'])
        #@tags = data['Tags']
        #@effort = data['Effort']
        #@time_spent = data['TimeSpent']
        #@last_state_change_date = parse_time(data['LastStateChangeDate'])
        #@original_data = original_data
      end

      # Parse the dot net time representation into something that ruby can use
      def parse_time(string)
        return nil unless string && !string.empty?

        Time.at(string.slice(6, 10).to_i)
      end
    end
  end
end
