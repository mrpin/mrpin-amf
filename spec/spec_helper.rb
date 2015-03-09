require 'rubygems'
require 'rspec'

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'amf'

Dir[File.dirname(__FILE__) + '/helpers/*.rb'].each { |file| require file }