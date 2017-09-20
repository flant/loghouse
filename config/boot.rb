require 'bundler'
require 'pathname'

Bundler.require(:default, ENV.fetch('RACK_ENV') { 'development' })

$LOAD_PATH.unshift Pathname.new(File.expand_path('.')).join('lib').to_s

require 'active_support/core_ext'

require 'parslet_extensions'
require 'loghouse_query'

require 'clickhouse_time_zone_patch'
require_relative 'clickhouse'

require 'will_paginate_bootstrap'
