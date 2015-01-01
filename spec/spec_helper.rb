require 'rubygems'
require 'rspec'

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rocketamf'
require 'rocketamf/pure/helpers/io_helper_write' # Just to make sure they get loaded
require 'rocketamf/pure/helpers/io_helper_read' # Just to make sure they get loaded

Dir[File.dirname(__FILE__) + '/helpers/*.rb'].each { |file| require file }