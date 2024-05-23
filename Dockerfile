FROM ruby:3.2-slim-bookworm
MAINTAINER Firespring "opensource@firespring.com"

# Set up the working directory
WORKDIR /usr/src/app

# Configure bundler to use multiple threads and retry if necessary
RUN bundle config --global jobs 12 && bundle config --global retry 3

# Update the OS packages and set up the default locale
# * build-essential required by nokogiri
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y locales apt-transport-https build-essential curl git \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

# Copy library specs in which will invalidate the cache if any libraries have been changed
ADD Gemfile .
ADD Gemfile.lock .
ADD firespring_dev_commands.gemspec .
ADD lib/firespring_dev_commands/version.rb ./lib/firespring_dev_commands/version.rb
RUN bundle config --local with 'test'
RUN bundle install

# Copy the rest of the source in
ADD . .
