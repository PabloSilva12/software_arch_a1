require 'elasticsearch'

class ElasticsearchService
  INDEXES = {
    authors: 'authors',
    books: 'books',
    reviews: 'reviews',
    author_summary: 'author_summary'
  }
  def self.author_summary_mapping
    {
      properties: {
        id: { type: 'keyword' },
        name: { type: 'text' },
        books_count: { type: 'integer' },
        average_score: { type: 'float' },
        total_sales: { type: 'integer' }
      }
    }
  end

  def self.reviews_mapping
    {
      properties: {
        id: { type: 'keyword' },
        book_id: { type: 'keyword' },
        number_of_up_votes: { type: 'integer' },
        review: { type: 'text' },
        score: { type: 'integer' }
      }
    }
  end
  def self.authors_mapping
    {
      properties: {
        id: { type: 'keyword' },
        name: { type: 'text' },
        date_of_birth: { type: 'date' },
        country_of_origin: { type: 'text' },
        short_description: { type: 'text' }
      }
    }
  end

  def self.books_mapping
    {
      properties: {
        id: { type: 'keyword' },
        name: { type: 'text' },
        summary: { type: 'text' },
        date_of_publication: { type: 'date' },
        number_of_sales: { type: 'integer' },
        author_id: { type: 'keyword' }
      }
    }
  end

  def self.client
    @client ||= begin
      Elasticsearch::Client.new(url: ENV['ELASTICSEARCH_URL'], log: true)
    rescue StandardError => e
      Rails.logger.error("Error initializing Elasticsearch client: #{e.message}")
      nil
    end
  end

  def self.index_exists?(index_name)
    client.indices.exists?(index: index_name)
  rescue StandardError => e
    Rails.logger.error("Error checking if index exists: #{e.message}")
    false
  end
  def self.create_index(index_name, mapping)
    unless client.indices.exists?(index: index_name)
      client.indices.create(index: index_name, body: { mappings: mapping })
      Rails.logger.info("Created index: #{index_name} with mapping: #{mapping}")
    else
      Rails.logger.info("Index already exists: #{index_name}")
    end
  rescue StandardError => e
    Rails.logger.error("Error creating index: #{e.message}")
  end

  def self.fetch_all_documents(index_name)
    return unless ElasticsearchService.client
  
    begin
      # Initialize a scroll query to retrieve all documents
      response = ElasticsearchService.client.search(
        index: index_name,
        scroll: '1m', # Time to keep the scroll context open
        body: {
          query: {
            match_all: {}
          }
        },
        size: 50 # Number of documents to fetch per batch
      )
  
      # Collect all documents
      documents = []
  
      # Get the initial set of documents
      scroll_id = response['_scroll_id']
      hits = response['hits']['hits']
      documents.concat(hits.map { |hit| hit['_source'] })
  
      # Continue scrolling if there are more documents
      while hits.any? do
        response = ElasticsearchService.client.scroll(scroll_id: scroll_id, scroll: '1m')
        scroll_id = response['_scroll_id']
        hits = response['hits']['hits']
        documents.concat(hits.map { |hit| hit['_source'] })
      end
      documents
    rescue StandardError => e
      Rails.logger.error("Error fetching all documents from index #{index_name}: #{e.message}")
      []
    end
  end
  
  def self.index_document(index_name, id= nil, body)
    return unless client
    if id.nil?
      # Use POST if no ID is provided, so Elasticsearch generates one automatically
      client.index(index: index_name, body: body)
    else
      # Use PUT if the ID is provided
      client.index(index: index_name, id: id, body: body)
    end
  rescue StandardError => e
    Rails.logger.error("Error indexing document: #{e.message}")
  end

  def self.update_document(index_name, id, body)
    return unless client
  
    client.update(index: index_name, id: id, body: { doc: body })
  rescue StandardError => e
    Rails.logger.error("Error updating document: #{e.message}")
  end

  def self.search(index_name, query)
    if client
      client.search(index: index_name, body: query)
    else
      Rails.logger.error("Elasticsearch client is not available for search.")
      []
    end
  rescue StandardError => e
    Rails.logger.error("Error executing search: #{e.message}")
    []
  end
 
  def self.delete_all_documents(index_name)
    return unless client

    begin
      # Delete all documents from the index
      response = client.delete_by_query(index: index_name, body: { query: { match_all: {} } })
      Rails.logger.info("Deleted all documents from index: #{index_name}. Response: #{response}")
    rescue StandardError => e
      Rails.logger.error("Error deleting documents from index #{index_name}: #{e.message}")
    end
  end

  def self.query(search_field, search_terms)
    {
      query: {
        bool: {
          must: [
            {
              multi_match: {
                query: search_terms,
                fields: [search_field],
                type: "best_fields",  # You can also try "phrase", or "most_fields"
                operator: "and"       # Ensures all terms must match
              }
            }
          ]
        }
      }
    }
  end

  def self.connected?
    client = self.client
    return false unless client

    begin
      # Perform a basic request to check connectivity
      response = client.info
      # If the response is successful (status code 200), return true
      response['cluster_name'].present? # Checking for presence of cluster name indicates connection is successful
    rescue Faraday::ConnectionFailed => e
      Rails.logger.error("Elasticsearch connection failed: #{e.message}")
      false
    rescue StandardError => e
      Rails.logger.error("An error occurred while checking Elasticsearch connection: #{e.message}")
      false
    end
  end
end
