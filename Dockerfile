# syntax = docker/dockerfile:1

# -------------------------------------------------------
# Dockerfile — production image
# Used by AWS ECS / ECR
# -------------------------------------------------------

ARG RUBY_VERSION=3.4.7
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"


# Build stage — compile gems + bootsnap
FROM base as build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/


# Final runtime image
FROM base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl postgresql-client && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log tmp
USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

# Default: web server. Override with CMD ["bundle","exec","sidekiq"] for worker tasks.
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
