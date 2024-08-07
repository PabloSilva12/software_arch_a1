namespace :cequel do
  desc "Create the Cequel schema"
  task :migrate => :environment do
    Cequel::Schema.create!
  end

  desc "Drop the Cequel schema"
  task :drop => :environment do
    Cequel::Schema.truncate!
  end
end
