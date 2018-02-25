# frozen_string_literal: true
require 'jirack'
require 'thor'
require 'uri'
require 'jira-ruby'
require 'slack/incoming/webhooks'

module Jirack
  class Command < Thor

    desc 'config', 'setting config'
    def config
      cred = Jirack::Credential.new


      host = ask "input host (ex. 'mydomain.atlassian.net') #{ cred.host&.empty? ? '' : "(#{cred.host})" }:"
      cred.host = host unless host.empty?

      project_name = ask "input project name #{ cred.project_name&.empty? ? '' : "(#{cred.project_name})" }:"
      cred.project_name = project_name unless project_name.empty?

      username = ask "input user name #{ cred.username&.empty? ? '' : "(#{cred.username})" }:"
      cred.username = username unless username.empty?

      password = ask '(required!)input password:', echo: false
      cred.password = password

      puts ''

      slack_webhook_url = ask "input slack webhook urk #{ cred.slack_webhook_url&.empty? ? '' : "(#{cred.slack_webhook_url})" }:"
      cred.slack_webhook_url = slack_webhook_url unless slack_webhook_url.empty?

      cred.store
    end

    desc 'list', 'show your active issue'
    method_option 'sum-point',  type: :boolean, desc: 'show your all issue point'
    def list
      cred = Jirack::Credential.new
      client = cred.jira_client

      active_sprint =  active_sprint(client, project_board(client, cred.project_name)['id'].to_i)

      if options.key?('sum-point')
        sum_points = active_sprint_issue(client, cred.project_name, active_sprint['name']).inject(0.0) {|sum, issue| sum + issue.points }
        puts "#{ active_sprint['name'] } points: #{ sum_points }"
      else
        puts "#{ active_sprint['name'] } issues: "
        active_sprint_issue(client, cred.project_name, active_sprint['name']).each do |issue|
          puts "#{ issue.key }: #{ issue.summary }(#{issue.id}) [#{ issue.points }] #{ issue.status.name } "
        end
      end
    end

    desc 'forward issue_number', 'forward issue status'
    method_option 'message',  :aliases => '-m', desc: 'notify slack message'
    def forward(issue_number)
      cred = Jirack::Credential.new
      client = cred.jira_client

      issue = client.Issue.find("#{ cred.project_name }-#{ issue_number }", { extend: 'transitions' })

      next_status = issue.status.next_status(client)

      next_transition =  issue.transitions.all.find {|transition| transition.to.id == next_status.id }

      transition = JIRA::Resource::Transition.new(client, :attrs => {id: next_transition.id }, :issue_id => issue.id)
      transition.save(transition: { id: next_transition.id })

      # slack に通知
      if options.key? :message
        slack = Slack::Incoming::Webhooks.new cred.slack_webhook_url
        slack.post "<@#{ issue.reporter.name }> #{ issue.summary }(#{ issue_url(issue) }) #{ options[:message] }"
      end

      puts "#{ cred.project_name }-#{ issue_number } forward to #{ next_transition.to.name }"
    end

    desc 'back issue_number', 'back issue status'
    method_option 'message',  :aliases => '-m', desc: 'notify slack message'
    def back(issue_number)
      cred = Jirack::Credential.new
      client = cred.jira_client

      issue = client.Issue.find("#{ cred.project_name }-#{ issue_number }", { extend: 'transitions' })

      next_status = issue.status.next_status(client)

      next_transition =  issue.transitions.all.find {|transition| transition.to.id != next_status.id }

      transition = JIRA::Resource::Transition.new(client, :attrs => {id: next_transition.id }, :issue_id => issue.id)
      transition.save(transition: { id: next_transition.id })

      # slack に通知
      if options.key? :message
        slack = Slack::Incoming::Webhooks.new cred.slack_webhook_url
        slack.post "<@#{ issue.reporter.name }> #{ issue.summary }(#{ issue_url(issue) }) #{ options[:message] }"
      end

      puts "#{ cred.project_name }-#{ issue_number } back to #{ next_transition.to.name }"
    end

    private

    def project_board(client, project_name)
      client.Agile.all['values'].find {|board| board['name'] == project_name }
    end

    def active_sprint(client, board_id)
      client.Agile.get_sprints(board_id, state: 'active')['values'].first
    end

    def active_sprint_issue(client, project_name, sprint_name)
      JIRA::Resource::Issue.jql(client, "project=\"#{ project_name }\" AND assignee = currentuser() AND cf[10007] = \"#{ sprint_name }\"")
    end

    def issue_url(issue)
      uri = URI.parse(issue.self)
      "https://#{ uri.host }/browse/#{ issue.key }"
    end
  end
end
