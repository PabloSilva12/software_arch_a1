namespace :db do
  desc "Seed the Cassandra database"
  task seed: :environment do
    # Example data
    Author.create(id: SecureRandom.uuid, name: 'John Doe', date_of_birth: '2021-01-01', nationality: 'shileno', description: 'buen sujeto')
    Author.create(id: SecureRandom.uuid, name: 'John Doe2', date_of_birth: '2021-01-02', nationality: 'shileno', description: 'buen sujeto2')

    puts "Database seeded!"
  end
end
