# frozen_string_literal: true
require 'jirack'
require 'jira-ruby'

module Jirack
  module StatusClassExtension
    WORK_FLOW_STATUS_IDS = [1, 3, 10_603, 10_600, 10_604, 10_001].freeze

    def work_flow_status(client, options = {})
      status_list = all(client, options)
      WORK_FLOW_STATUS_IDS.map {|id| status_list.find { |status| status.id.to_i == id } }
    end

  end

  module StatusExtension

    def next_status(client)
      index = StatusClassExtension::WORK_FLOW_STATUS_IDS.index {|id| self.id.to_i == id }

      return if index + 1 == StatusClassExtension::WORK_FLOW_STATUS_IDS.size

      client.Status.all.find {|status| status.id.to_i == StatusClassExtension::WORK_FLOW_STATUS_IDS[index + 1] }
    end
  end
end


JIRA::Resource::Status.send(:extend, Jirack::StatusClassExtension)
JIRA::Resource::Status.send(:include, Jirack::StatusExtension)
