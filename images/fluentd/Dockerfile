FROM ubuntu:18.04
COPY clean-apt /usr/bin
COPY clean-install /usr/bin
COPY fluentd-systemd-plugin.patch /opt
COPY Gemfile /Gemfile
ARG repository="deb http://repo.yandex.ru/clickhouse/deb/stable/ main/"
ARG version=20.1.2.4

# Copy the Fluentd configuration file for logging Docker container logs.
COPY fluent.conf /etc/fluent/fluent.conf
COPY insert_ch.sh /usr/local/bin/insert_ch.sh
COPY run.sh /run.sh
COPY migrate-tables.sh /usr/local/bin/migrate-tables.sh

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
                     gnupg \
    && echo 'gem: --no-document' >> /etc/gemrc \
    && gem install --file Gemfile \
    && cd /tmp \
    && echo $repository | tee /etc/apt/sources.list.d/clickhouse.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4 \
    && apt-get update \
    && apt-get install -y patch tzdata clickhouse-common-static=$version clickhouse-client=$version \
    && apt-get purge -y --auto-remove \
                     -o APT::AutoRemove::RecommendsImportant=false \
                     $BUILD_DEPS \
    && clean-apt \
    && rm -rf /var/lib/apt/lists/* \
    # Ensure fluent has enough file descriptors
    && ulimit -n 65536 \
    # patch fluentd
    # https://github.com/reevoo/fluent-plugin-systemd/pull/41
    # && patch /var/lib/gems/2.3.0/gems/fluent-plugin-systemd-0.0.8/lib/fluent/plugin/in_systemd.rb /opt/fluentd-systemd-plugin.patch
    && chmod +x /usr/local/bin/insert_ch.sh /usr/local/bin/migrate-tables.sh /run.sh

# Expose prometheus metrics.
EXPOSE 80

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1

# Start Fluentd to pick up our config that watches Docker container logs.
CMD /run.sh $FLUENTD_ARGS
