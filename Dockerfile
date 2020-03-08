FROM ruby:2.6.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs \
    && mkdir /app \
    && adduser --disabled-password --system --home /app --shell /bin/bash --no-create-home --uid 7000 app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
ADD . /app
RUN cd /app && bundle config git.allow_insecure true && bundle install && chown app:nogroup -R /app
WORKDIR /app
USER app
EXPOSE 3000
CMD ["bundle", "exec", "puma"]
