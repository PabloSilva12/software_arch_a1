namespace :db do
  desc "Seed data for Cassandra"
  task seed: :environment do
    require "#{Rails.root}/app/db/seeds.rb"
  end
end
