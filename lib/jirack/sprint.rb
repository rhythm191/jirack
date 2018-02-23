# frozen_string_literal: true
require 'jirack'
require 'jira-ruby'

module Jirack
  class Sprint

    attr_accessor :name, :state, :start_date, :end_date

    def initialize(field_string)
      sprint_array = field_string[0].split(',')

      @name = sprint_array[3].split('=')[1]
      @state = sprint_array[2].split('=')[1]

      start_date_string = sprint_array[5].split('=')[1]
      if start_date_string != '<null>'
        @start_date = DateTime.parse(start_date_string)
      end

      end_date_string = sprint_array[6].split('=')[1]
      if end_date_string != '<null>'
        @start_date = DateTime.parse(end_date_string)
      end
    end

    def number
      @name.split(' ')[1].to_i
    end

    def active?
      @state == 'ACTIVE'
    end

    def future?
      @state == 'FUTURE'
    end

    def self.active_sprint(client)
      cred = Jirack::Credential.new

      JIRA::Resource::Issue.jql(client, "project=\"#{ cred.project_name }\" AND assignee = currentuser()").find do |issue|
        issue.sprint.active?
      end.sprint
    end

    def to_s
      "Jirack::Sprint name: #{ @name }, state: #{ @state }, start_date: #{ @start_date }, end_date: #{ @end_date }"
    end
  end
end
