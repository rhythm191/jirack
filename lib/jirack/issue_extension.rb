# frozen_string_literal: true
require 'jirack'
require 'jira-ruby'

module Jirack
  module IssueExtention
    def sprint
      Sprint.new self.customfield_10007
    end

    def points
      self.customfield_10004.to_i
    end

    def key_id
      self.key.split('-')[1].to_i
    end

    def assign_user_name
      self.assignee&.name&.split('@')&.first
    end


    private


  end
end


JIRA::Resource::Issue.send(:include, Jirack::IssueExtention)
