require 'rubygems'
require 'bundler'

Bundler.require

unless ENV['GITHUB_TOKEN']
  raise StandardError.new('Please set GITHUB_TOKEN in your .env file')
end

require './settings'
require './github'

get '/' do
  @filter_labels        = params.dig(:filter, :label).to_s.split(',')
  @filter_states        = params.dig(:filter, :state).to_s.split(',')
  @pagination_cursor    = params.dig(:pagination, :cursor)
  @pagination_direction = params.dig(:pagination, :direction)
  @pagination_limit     = params.dig(:pagination, :limit).to_i
  @repository_name      = 'rails'
  @repository_owner     = 'rails'
  @sort_direction       = params.dig(:sort, :direction)
  @sort_field           = params.dig(:sort, :field)

  unless (
      @filter_labels.length > 0 &&
      @filter_labels.uniq.length == @filter_labels.length &&
      (@filter_labels - FILTER_LABEL_WHITELIST).length == 0
  )
    @new_filter_labels = FILTER_LABEL_WHITELIST
  end

  unless (
      @filter_states.length > 0 &&
      @filter_states.uniq.length == @filter_states.length &&
      (@filter_states - FILTER_STATE_WHITELIST).length == 0
  )
    @new_filter_states = %w{open}
  end

  unless PAGINATION_DIRECTION_WHITELIST.include?(@pagination_direction)
    @new_pagination_direction = PAGINATION_DIRECTION_WHITELIST.first
  end

  unless PAGINATION_LIMIT_RANGE === @pagination_limit
    @new_pagination_limit = (PAGINATION_LIMIT_RANGE.sum / PAGINATION_LIMIT_RANGE.size)
  end

  unless SORT_DIRECTION_WHITELIST.include?(@sort_direction)
    @new_sort_direction = SORT_DIRECTION_WHITELIST.last
  end

  unless SORT_FIELD_WHITELIST.include?(@sort_field)
    @new_sort_field = SORT_FIELD_WHITELIST.last
  end

  if (
    @new_filter_labels ||
    @new_filter_states ||
    @new_pagination_direction ||
    @new_pagination_limit ||
    @new_sort_direction ||
    @new_sort_field
  )
    raw_new_url = <<~URL
      /
      ?filter[label]=#{@new_filter_labels&.join(',') || @filter_labels&.join(',')}
      &filter[state]=#{@new_filter_states&.join(',') || @filter_states&.join(',')}
      &pagination[direction]=#{@new_pagination_direction || @pagination_direction}
      &pagination[limit]=#{@new_pagination_limit || @pagination_limit}
      &sort[direction]=#{@new_sort_direction || @sort_direction}
      &sort[field]=#{@new_sort_field || @sort_field}
    URL
    new_url = raw_new_url.gsub("\n", '')
    return redirect to(new_url)
  end

  # TODO: Refactor - Could not figure out how to conditionally set dynamic
  # graphql parameters
  repository_issues_query =
    case @pagination_direction
    when 'before'
      Github::Queries::RepositoryIssuesBefore
    when 'after'
      Github::Queries::RepositoryIssuesAfter
    else
      raise StandardError.new('Should not happen')
    end

  begin
    @query_response = Github::Client.query(
      repository_issues_query,
      variables: {
        filter_labels: @filter_labels,
        filter_states: @filter_states.map(&:upcase),
        pagination_cursor: @pagination_cursor,
        pagination_limit: @pagination_limit,
        repository_name: @repository_name,
        repository_owner: @repository_owner,
        sort_direction: (@sort_direction == 'ascending') ? 'ASC' : 'DESC',
        sort_field: @sort_field.upcase,
      }
    )
  rescue StandardError => exception
    case exception
    when SocketError
      halt(
        504,
        {
          'Content-Type' => 'application/json'
        },
        {
          error: 'Could not reach gateway',
          code: 504
        }.to_json
      )
    else
      halt(
        500,
        {
          'Content-Type' => 'application/json'
        },
        {
          error: 'Server Error',
          code: 500
        }.to_json
      )
    end
  end

  if @query_response.errors.any?
    halt(
      502,
      {
        'Content-Type' => 'application/json'
      },
      {
        error: 'Bad Gateway',
        code: 502,
        data: @query_response.errors.messages
      }.to_json
    )
  end

  if request.accept?('text/html')
    content_type :html
    erb :index
  elsif request.accept?('application/json')
    content_type :json
    {
      links: {
        self: request.url,
        before: @query_response.data.repository.issues.page_info.has_previous_page ? "#{request.base_url}/?filter[label]=#{@filter_labels.join(',')}&filter[state]=#{@filter_states.join(',')}&pagination[cursor]=#{@query_response.data.repository.issues.page_info.start_cursor}&pagination[direction]=before&pagination[limit]=#{@pagination_limit}&sort[direction]=#{@sort_direction}&sort[field]=#{@sort_field}" : nil ,
        after: @query_response.data.repository.issues.page_info.has_next_page ? "#{request.base_url}/?filter[label]=#{@filter_labels.join(',')}&filter[state]=#{@filter_states.join(',')}&pagination[cursor]=#{@query_response.data.repository.issues.page_info.end_cursor}&pagination[direction]=after&pagination[limit]=#{@pagination_limit}&sort[direction]=#{@sort_direction}&sort[field]=#{@sort_field}" : nil,
      },
      data: @query_response.data.repository.issues.edges.map do |issue|
        {
          type: 'issues',
          id: issue.node.id,
          attributes: {
            created_at: issue.node.created_at,
            comment_count: issue.node.comments.total_count,
            labels: (issue.node.labels.edges.map{|edge| edge.node.name } & FILTER_LABEL_WHITELIST),
            number: issue.node.number,
            state: issue.node.state,
            title: issue.node.title,
            url: issue.node.url
          }
        }
      end
    }.to_json
  else
    content_type :html
    erb :index
  end
end
