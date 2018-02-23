# frozen_string_literal: true
require 'json'
require 'jira-ruby'

module Jirack
  class Credential

    attr_accessor :username, :domain, :project_name, :password

    CREDENTIAL_FILE_PATH = '~/.jirack'

    def initialize(filename = CREDENTIAL_FILE_PATH)
      if File.exists?(File.expand_path(filename))
        json = open(File.expand_path(filename)) {|io| JSON.load(io) }
        @username = json['username']
        @domain = json['domain']
        @project_name = json['project_name'].upcase
        @password = json['password']
      end
    end

    def to_json
      hash = {}
      instance_variables.each {|var| hash[var.to_s.delete('@')] = instance_variable_get(var) }
      hash.to_json
    end

    def store
      File.open(File.expand_path(CREDENTIAL_FILE_PATH), 'w', 0600) do |file|
        file.puts self.to_json
      end
    end

    def jira_client
      client_options = {
        :username => @username,
        :password => @password,
        :site     => @domain,
        :context_path => '',
        :auth_type => :basic,
        :read_timeout => 120
      }

      JIRA::Client.new(client_options)
    end
  end
end
