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
          puts "#{ issue.key }: #{ issue.summary } [#{ issue.points }] #{ issue.status.name } "
        end
      end
    end

    desc 'forward issue_number', 'forward issue status'
    def forward(issue_number)
      cred = Jirack::Credential.new
      client = cred.jira_client

      issue = client.Issue.find("#{ cred.project_name}-#{issue_number}", { extend: 'transitions' })

      next_status = issue.status.next_status(client)

      next_transition =  issue.transitions.all.find {|transition| transition.to.id == next_status.id }

      transition = JIRA::Resource::Transition.new(client, :attrs => {id: next_transition.id }, :issue_id => issue.id)
      transition.save(transition: { id: next_transition.id })
    end

    desc 'back issue_number', 'back issue status'
    def back(issue_number)
      cred = Jirack::Credential.new
      client = cred.jira_client

      issue = client.Issue.find("#{ cred.project_name}-#{issue_number}", { extend: 'transitions' })

      next_status = issue.status.next_status(client)

      next_transition =  issue.transitions.all.find {|transition| transition.to.id != next_status.id }

      transition = JIRA::Resource::Transition.new(client, :attrs => {id: next_transition.id }, :issue_id => issue.id)
      transition.save(transition: { id: next_transition.id })
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
  end
end
