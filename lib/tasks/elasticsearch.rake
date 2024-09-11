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
            author_id: { type: 'keyword' },
            cover_image_url: { type: 'text'}
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
  end
end