# frozen_string_literal: true
require 'jirack'
require 'jira-ruby'

module Jirack
  module IssueExtention
    def sprint
      sprint_array = self.customfield_10007[0].split(',')

      {
        name: sprint_array[3].split('=')[1],
        number: sprint_array[3].split('=')[1].split(' ')[1].to_i,
        state: sprint_array[2].split('=')[1],
        start_date: DateTime.parse(sprint_array[5].split('=')[1]),
        end_date: DateTime.parse(sprint_array[6].split('=')[1])
      }
    end

    def points
      self.customfield_10004
    end

    private


  end
end


JIRA::Resource::Issue.send(:include, Jirack::IssueExtention)
