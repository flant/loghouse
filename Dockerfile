FROM ruby:2.3.4
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /app
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle config git.allow_insecure true
RUN bundle install
ADD . /app
EXPOSE 3000
CMD ["bundle", "exec", "puma"]
