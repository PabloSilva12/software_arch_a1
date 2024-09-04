module ElasticsearchClient
    def self.client
      @client ||= Elasticsearch::Client.new(url: ENV['ELASTICSEARCH_URL'] || 'http://elasticsearch:9200', log: true)
    end
  
    def self.index_exists?(index_name)
      client.indices.exists?(index: index_name)
    end
  
    def self.create_index(index_name, settings = {})
      client.indices.create(index: index_name, body: settings) unless index_exists?(index_name)
    end

    def self.update_document(index_name, id, body)
      @client.update(
        index: index_name,
        id: id,
        body: { doc: body }
      )
    end
  
    def self.index_document(index_name, id, body)
      client.index(index: index_name, id: id, body: body)
    end
  
    def self.delete_document(index_name, id)
      client.delete(index: index_name, id: id)
    end
  
    def self.search(index_name, query)
      client.search(index: index_name, body: query)
    end
  end
  