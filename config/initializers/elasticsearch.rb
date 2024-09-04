require 'elasticsearch'

Elasticsearch::Model.client = Elasticsearch::Client.new(
  url: ENV['ELASTICSEARCH_URL'] || 'http://elasticsearch:9200', # Use the service name 'elasticsearch'
  log: true
)
