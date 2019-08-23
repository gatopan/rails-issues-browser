FILTER_LABEL_WHITELIST = [
  'actioncable',
  'actionmailer',
  'actionpack',
  'actionview',
  'activejob',
  'activemodel',
  'activerecord',
  'activestorage',
  'activesupport',
  'asset pipeline',
].freeze

FILTER_STATE_WHITELIST = %w{open closed}.freeze

PAGINATION_LIMIT_RANGE = (1..100).freeze

PAGINATION_DIRECTION_WHITELIST = %w{after before}.freeze

SORT_DIRECTION_WHITELIST = %w{ascending descending}.freeze

SORT_FIELD_WHITELIST = %w{created_at comments}.freeze
