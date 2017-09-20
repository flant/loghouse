require 'bundler'
require 'pathname'

Bundler.require(:default, ENV.fetch('RACK_ENV') { 'development' })

$LOAD_PATH.unshift Pathname.new(File.expand_path('.')).join('lib').to_s

require 'loghouse_query'
