module Github
  HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(context)
      {
        'Authorization': "Bearer #{ENV.fetch('GITHUB_TOKEN')}"
      }
    end
  end
  # NOTE - Disabled intentionally to increase boot speed
  # Schema = GraphQL::Client.load_schema(HTTP)
  # GraphQL::Client.dump_schema(HTTP, 'github-graphql-schema.json')
  Schema = GraphQL::Client.load_schema('github-graphql-schema.json')
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  module Queries
    RawRepositoryIssues = <<~GRAPHQL
      query(
        $filter_labels: [String!]!,
        $filter_states: [IssueState!]!,
        $pagination_cursor: String,
        $pagination_limit: Int!,
        $repository_name: String!,
        $repository_owner: String!,
        $sort_direction: OrderDirection!,
        $sort_field: IssueOrderField!
      ) {
        repository(
          owner: $repository_owner,
          name: $repository_name
        ) {
          issues(
            first: $pagination_limit,
            after: $pagination_cursor,
            states: $filter_states,
            filterBy: {
              labels: $filter_labels
            },
            orderBy: {
              field: $sort_field,
              direction: $sort_direction
            }
          ) {
            edges {
              cursor
              node {
                id
                number
                url
                title
                state
                createdAt
                comments {
                  totalCount
                }
                labels(first: 100) {
                  edges {
                    node {
                      name
                    }
                  }
                }
              }
            }
            pageInfo {
              startCursor
              hasNextPage
              hasPreviousPage
              endCursor
            }
            totalCount
          }
        }
      }
    GRAPHQL
    # TODO: Refactor - Could not figure out how to conditionally set dynamic
    # graphql parameters
    RepositoryIssuesAfter  = Client.parse(RawRepositoryIssues)
    RepositoryIssuesBefore = Client.parse(
      RawRepositoryIssues
        .sub("after: $pagination_cursor", "before: $pagination_cursor")
        .sub("first: $pagination_limit", "last: $pagination_limit")
    )
  end
end
