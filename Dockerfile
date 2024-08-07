
FROM ruby:3.2.2


RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

ENV RAILS_ROOT /var/www/my_app
RUN mkdir -p $RAILS_ROOT

WORKDIR $RAILS_ROOT


COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install
RUN rake cequel:migrate
RUN rake db:seed

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
