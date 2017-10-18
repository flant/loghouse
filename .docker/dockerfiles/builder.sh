#!/bin/bash

echo "Building clickhouse server..."
cd clickhouse/ && \
  docker build -t clickhouse . && \
  docker tag clickhouse wimbo/clickhouse && \
  docker push wimbo/clickhouse && \
  cd .. && \
echo "Building clickhouse server complete!"

echo "Building fluentd..."
cd fluentd/ && \
  docker build -t fluentd . && \
  docker tag fluentd wimbo/fluentd && \
  docker push wimbo/fluentd && \
  cd .. && \
echo "Building fluentd complete!"

echo "Building tabix..."
cd tabix.ui/ && \
  docker build -t tabix . && \
  docker tag tabix wimbo/tabix && \
  docker push wimbo/tabix && \
  cd .. && \
echo "Building tabix complete!" 

echo "Building loghouse..."
cd ../../ && \
  docker build -t loghouse . && \
  docker tag loghouse wimbo/loghouse && \
  docker push wimbo/loghouse && \
  cd - && \
echo "Building loghouse complete!"
