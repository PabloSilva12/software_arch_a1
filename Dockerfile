# Dockerfile
FROM ruby:3.2.2

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

WORKDIR /my_app
COPY Gemfile /my_app/Gemfile
COPY Gemfile.lock /my_app/Gemfile.lock

RUN bundle install

COPY . /my_app

CMD ["rails", "server", "-b", "0.0.0.0"]
