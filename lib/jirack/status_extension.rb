# frozen_string_literal: true
require 'jirack'
require 'jira-ruby'

module Jirack
  module StatusExtention
    WORK_FLOW_STATUS_IDS = [1, 3, 10_600, 10_603, 10_604, 10_001].freeze

    def work_flow_status(client, options = {})
      status_list = all(client, options)
      WORK_FLOW_STATUS_IDS.map {|id| status_list.find { |status| status.id.to_i == id } }
    end
  end
end


JIRA::Resource::Status.send(:extend, Jirack::StatusExtention)
