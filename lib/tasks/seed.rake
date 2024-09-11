namespace :db do
  desc "Seed data for Cassandra"
  task seed: :environment do
    require "#{Rails.root}/db/seeds.rb"
  end
end

namespace :elastic do
  desc "Seed data for Elasticsearch"
  task seed: :environment do
    require "#{Rails.root}/db/elasticsearch_seed.rb"
  end
end
