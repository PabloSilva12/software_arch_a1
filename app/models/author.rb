class Author
  include Cequel::Record

  key :id, :uuid, auto: true
  column :name, :text
  column :date_of_birth, :timestamp
  column :nationality, :text
  column :description, :text
end
