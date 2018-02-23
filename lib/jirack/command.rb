# frozen_string_literal: true
require 'jirack'
require 'thor'
require 'jira-ruby'

module Jirack
  class Command < Thor

    desc 'config', 'setting config'
    def config
      cred = Jirack::Credential.new


      domain = ask "input domain (ex. 'http://mydomain.atlassian.net/') #{ cred.domain&.empty? ? '' : "(#{cred.domain})" }:"
      cred.domain = domain unless domain.empty?

      project_name = ask "input project name #{ cred.project_name&.empty? ? '' : "(#{cred.project_name})" }:"
      cred.project_name = project_name unless project_name.empty?

      username = ask "input user name #{ cred.username&.empty? ? '' : "(#{cred.username})" }:"
      cred.username = username unless username.empty?

      password = ask '(required!)input password:', echo: false
      cred.password = password

      cred.store
    end

    desc 'list', 'show now your issue'
    def list
      cred = Jirack::Credential.new


      options = {
        :username => cred.username,
        :password => cred.password,
        :site     => cred.domain,
        :context_path => '',
        :auth_type => :basic,
        :read_timeout => 120
      }

      client = JIRA::Client.new(options)

      JIRA::Resource::Issue.jql(client, "project=\"#{ cred.project_name }\" AND assignee = currentuser()").take(1).each do |issue|
        p issue
        p issue.status

        puts "#{issue.id} - #{issue.summary} - #{ issue.labels}"

        # puts "#{issue.sprint}"
        puts issue.key
        puts "#{issue.points}"
        puts "#{issue.status.name}"

        puts issue.sprint
      end

      JIRA::Resource::Issue.jql(client, "key=\"#{ cred.project_name }-3390\"").each do |issue|

        puts issue.key
        puts "#{issue.status.name}"
        puts issue.sprint
        puts issue.status
      end

      JIRA::Resource::Status.work_flow_status(client).each do |status_category|
        puts status_category.name
      end
    end
  end
end
