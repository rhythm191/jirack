# frozen_string_literal: true
require 'jirack'
require 'thor'
require 'uri'
require 'jira-ruby'
require 'slack/incoming/webhooks'
require 'launchy'

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
    method_option 'all', type: :boolean, aliases: '-a', desc: 'show all issue'
    method_option 'unassign', type: :boolean, aliases: '-u', desc: 'show all unassign issue'
    method_option 'sum-point', type: :boolean, aliases: '-n', desc: 'show your all issue point'
    def list
      cred = Jirack::Credential.new
      client = cred.jira_client

      active_sprint =  active_sprint(client, project_board(client, cred.project_name)['id'].to_i)

      if options.key?('unassign')
        puts "#{ active_sprint['name'] } unassign issues: "
        active_unassign_issue(client, cred.project_name, active_sprint['name']).each do |issue|
          puts "%s %s %4.1f %s" % [issue.key, mb_rjust(issue.status.name, 25), issue.points, issue.summary]
        end

      elsif options.key?('sum-point')
        sum_points = active_assign_issue(client, cred.project_name, active_sprint['name']).inject(0.0) {|sum, issue| sum + issue.points }
        puts "#{ active_sprint['name'] } points: #{ sum_points }"

      elsif options.key?('all')
        puts "#{ active_sprint['name'] } issues: "
        active_sprint_issue(client, cred.project_name, active_sprint['name']).each do |issue|
          puts "%s % 18s %s %4.1f %s" % [issue.key, issue.assign_user_name, mb_rjust(issue.status.name, 25), issue.points, issue.summary]
        end
      else
        puts "#{ active_sprint['name'] } issues: "
        active_assign_issue(client, cred.project_name, active_sprint['name']).each do |issue|
          puts "%s %s %4.1f %s" % [issue.key, mb_rjust(issue.status.name, 25), issue.points, issue.summary]
        end
      end
    end

    desc 'forward issue_number', 'forward issue status'
    method_option 'message',  aliases: '-m', desc: 'notify slack message'
    def forward(issue_number)
      cred = Jirack::Credential.new
      client = cred.jira_client

      issue = client.Issue.find("#{ cred.project_name }-#{ issue_number }", { extend: 'transitions' })

      next_status = issue.status.next_status(client, cred.workflow_ids)

      next_transition =  issue.transitions.all.find {|transition| transition.to.id == next_status.id }

      transition = JIRA::Resource::Transition.new(client, :attrs => {id: next_transition.id }, :issue_id => issue.id)
      transition.save(transition: { id: next_transition.id })


      puts "#{ cred.project_name }-#{ issue_number } forward to #{ next_transition.to.name }"

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

      next_status = issue.status.next_status(client, cred.workflow_ids)

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

    desc 'notify issue_number', 'notify issue message'
    method_option 'message',  :aliases => '-m', required: true, desc: 'notify slack message'
    def notify(issue_number)
      cred = Jirack::Credential.new
      client = cred.jira_client

      issue = client.Issue.find("#{ cred.project_name }-#{ issue_number }")

      # slack に通知
      if options.key? :message
        slack = Slack::Incoming::Webhooks.new cred.slack_webhook_url
        slack.post "<@#{ issue.reporter.name }> #{ issue.summary }(#{ issue_url(issue) }) #{ options[:message] }"
      end

      puts "#{ cred.project_name }-#{ issue_number } notify slack"
    end

    desc 'open issue_number', 'open browser issue page'
    def open(issue_number)
      cred = Jirack::Credential.new
      client = cred.jira_client

      issue = client.Issue.find("#{ cred.project_name }-#{ issue_number }")

      Launchy.open issue_url(issue)

    end

    desc 'assign issue_number', 'assign issue to you'
    def assign(issue_number)
      cred = Jirack::Credential.new
      client = cred.jira_client

      issue = client.Issue.find("#{ cred.project_name }-#{ issue_number }")

      myself = JIRA::Resource::UserFactory.new(client).myself

      client.put("/rest/api/2/issue/#{ issue.key }/assignee", { name: myself.name }.to_json)
    end

    private

    def project_board(client, project_name)
      client.Agile.all['values'].find {|board| board['name'] == project_name }
    end

    def active_sprint(client, board_id)
      client.Agile.get_sprints(board_id, state: 'active')['values'].first
    end

    def active_assign_issue(client, project_name, sprint_name)
      JIRA::Resource::Issue.jql(client, "project=\"#{ project_name }\" AND assignee = currentuser() AND cf[10007] = \"#{ sprint_name }\"")
    end

    def active_unassign_issue(client, project_name, sprint_name)
      JIRA::Resource::Issue.jql(client, "project=\"#{ project_name }\" AND assignee = NULL AND cf[10007] = \"#{ sprint_name }\"")
    end

    def active_sprint_issue(client, project_name, sprint_name)
      JIRA::Resource::Issue.jql(client, "project=\"#{ project_name }\" AND cf[10007] = \"#{ sprint_name }\" ORDER BY assignee")
    end

    def issue_url(issue)
      uri = URI.parse(issue.self)
      "https://#{ uri.host }/browse/#{ issue.key }"
    end

    def mb_rjust(string, width, padding=' ')
      output_width = string.each_char.map{|c| c.bytesize == 1 ? 1 : 2}.reduce(0, &:+)
      padding_size = [0, width - output_width].max
      padding * padding_size + string
    end
  end
end
