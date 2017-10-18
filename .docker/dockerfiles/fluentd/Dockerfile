# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This Dockerfile will build an image that is configured
# to run Fluentd with an Elasticsearch plug-in and the
# provided configuration file.
# The image acts as an executable for the binary /usr/sbin/td-agent.
# Note that fluentd is run with root permssion to allow access to
# log files with root only access under /var/log/containers/*

FROM ubuntu:16.04
COPY clean-apt /usr/bin
COPY clean-install /usr/bin
COPY Gemfile /Gemfile
ARG repository="deb http://repo.yandex.ru/clickhouse/xenial stable main"
ARG version=\*

# 1. Install & configure dependencies.
# 2. Install fluentd via ruby.
# 3. Remove build dependencies.
# 4. Cleanup leftover caches & files.
RUN BUILD_DEPS="make gcc g++ libc6-dev ruby-dev" \
    && clean-install $BUILD_DEPS \
                     ca-certificates \
                     libjemalloc1 \
                     ruby \
                     wget \
    && echo 'gem: --no-document' >> /etc/gemrc \
    && gem install --file Gemfile \
    && cd /tmp \
    && echo $repository | tee /etc/apt/sources.list.d/clickhouse.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4 \
    && apt-get update \
    && apt-get install tzdata clickhouse-server-base=$version clickhouse-client=$version \
    && apt-get purge -y --auto-remove \
                     -o APT::AutoRemove::RecommendsImportant=false \
                     $BUILD_DEPS \
    && clean-apt \
    && rm -rf /var/lib/apt/lists/* \
    # Ensure fluent has enough file descriptors
    && ulimit -n 65536

# Copy the Fluentd configuration file for logging Docker container logs.
COPY fluent.conf /etc/fluent/fluent.conf
COPY insert_ch.sh /usr/local/bin/insert_ch.sh
COPY insert_system_ch.sh /usr/local/bin/insert_system_ch.sh
COPY run.sh /run.sh
RUN chmod +x /usr/local/bin/insert_ch.sh

# Expose prometheus metrics.
EXPOSE 80

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1

# Start Fluentd to pick up our config that watches Docker container logs.
CMD /run.sh $FLUENTD_ARGS
