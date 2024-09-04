namespace :elasticsearch do
    desc 'Create Elasticsearch indexes'
    task create_indexes: :environment do
      client = Elasticsearch::Model.client
  
      # Define index for books
      client.indices.create(
        index: 'books',
        body: {
          settings: {
            number_of_shards: 1,
            number_of_replicas: 0
          },
          mappings: {
            properties: {
              name: { type: 'text' },
              summary: { type: 'text' }
            }
          }
        },
        ignore: [400] # Ignore index already exists errors
      )
  
      # Define index for reviews
      client.indices.create(
        index: 'reviews',
        body: {
          settings: {
            number_of_shards: 1,
            number_of_replicas: 0
          },
          mappings: {
            properties: {
              review: { type: 'text' }
            }
          }
        },
        ignore: [400] # Ignore index already exists errors
      )
    end
  end
  