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
              id: { type: 'keyword' },
              name: { type: 'text' },
              summary: { type: 'text' },
              date_of_publication: { type: 'date' },
              number_of_sales: { type: 'integer' },
              author_id: { type: 'keyword' }
            }
          }
        },
        ignore: [400] # Ignore index already exists errors
      )
  
      # Define index for authors
      client.indices.create(
        index: 'authors',
        body: {
          settings: {
            number_of_shards: 1,
            number_of_replicas: 0
          },
          mappings: {
            properties: {
              id: { type: 'keyword' },
              name: { type: 'text' },
              date_of_birth: { type: 'date' },
              country_of_origin: { type: 'text' },
              short_description: { type: 'text' }
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
              id: { type: 'keyword' },
              review: { type: 'text' },
              score: { type: 'integer' },
              number_of_up_votes: { type: 'integer' },
              book_id: { type: 'keyword' }
            }
          }
        },
        ignore: [400] # Ignore index already exists errors
      )
  
      # Define index for sales
      client.indices.create(
        index: 'sales',
        body: {
          settings: {
            number_of_shards: 1,
            number_of_replicas: 0
          },
          mappings: {
            properties: {
              id: { type: 'keyword' },
              book_id: { type: 'keyword' },
              year: { type: 'integer' },
              sales: { type: 'integer' }
            }
          }
        },
        ignore: [400] # Ignore index already exists errors
      )
    end
  
    desc 'Delete Elasticsearch indexes'
    task delete_indexes: :environment do
      client = Elasticsearch::Model.client
  
      # Delete index for books if it exists
      if client.indices.exists?(index: 'books')
        client.indices.delete(index: 'books')
        puts "Deleted 'books' index."
      else
        puts "'books' index does not exist."
      end
  
      # Delete index for authors if it exists
      if client.indices.exists?(index: 'authors')
        client.indices.delete(index: 'authors')
        puts "Deleted 'authors' index."
      else
        puts "'authors' index does not exist."
      end
  
      # Delete index for reviews if it exists
      if client.indices.exists?(index: 'reviews')
        client.indices.delete(index: 'reviews')
        puts "Deleted 'reviews' index."
      else
        puts "'reviews' index does not exist."
      end
  
      # Delete index for sales if it exists
      if client.indices.exists?(index: 'sales')
        client.indices.delete(index: 'sales')
        puts "Deleted 'sales' index."
      else
        puts "'sales' index does not exist."
      end
    end
  end
  