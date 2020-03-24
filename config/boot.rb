require 'bundler'
require 'pathname'

Bundler.require(:default, ENV.fetch('RACK_ENV') { 'development' })

$LOAD_PATH.unshift Pathname.new(File.expand_path('.')).join('lib').to_s

require 'yaml'
require 'json'
require 'active_support/core_ext'
require 'active_support/json'

require 'kubernetes'
require 'user'

require 'parslet_extensions'
require 'log'
require 'logs_tables'
require 'loghouse_query'

require 'clickhouse_time_zone_patch'
require 'clickhouse_read_timeout_patch'
require_relative 'clickhouse'

require 'datepicker_presets'
