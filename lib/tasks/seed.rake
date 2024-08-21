namespace :db do
  desc "Seed data for Cassandra"
  task seed: :environment do
    require "#{Rails.root}/db/seeds.rb"
  end
end
