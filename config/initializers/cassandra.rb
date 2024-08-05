# config/cassandra.rb

require 'cassandra'
require 'yaml'

# Load Cassandra configuration
CASSANDRA_CONFIG = YAML.load_file(Rails.root.join('config', 'cassandra.yml'))[Rails.env].deep_symbolize_keys

# Maximum number of retry attempts
MAX_RETRIES = 5
# Wait time between retries
WAIT_TIME = 15 # seconds

def connect_to_cassandra
  retries = 0

  begin
    cluster = Cassandra.cluster(
      hosts: CASSANDRA_CONFIG[:hosts],
      port: CASSANDRA_CONFIG[:port]
    )
    session = cluster.connect(CASSANDRA_CONFIG[:keyspace])

    # Store the session in Rails configuration
    Rails.application.config.cassandra_session = session
    Rails.logger.info "Connected to Cassandra successfully."
  rescue StandardError => e
    if retries < MAX_RETRIES
      retries += 1
      Rails.logger.warn "Failed to connect to Cassandra (attempt #{retries}): #{e.message}. Retrying in #{WAIT_TIME} seconds..."
      sleep WAIT_TIME
      retry
    else
      Rails.logger.error "Failed to connect to Cassandra after #{MAX_RETRIES} attempts: #{e.message}"
      raise "Failed to connect to Cassandra: #{e.message}"
    end
  end
end

# Establish connection on initialization
connect_to_cassandra
