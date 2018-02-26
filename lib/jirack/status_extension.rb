# frozen_string_literal: true
require 'jirack'
require 'jira-ruby'

module Jirack
  module StatusExtension

    def next_status(client, workflow_ids)
      index = workflow_ids.index {|id| self.id.to_i == id }

      return if index + 1 == workflow_ids.size

      client.Status.all.find {|status| status.id.to_i == workflow_ids[index + 1] }
    end
  end
end

JIRA::Resource::Status.send(:include, Jirack::StatusExtension)
