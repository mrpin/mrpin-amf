begin
  # Fat binaries for Windows
  RUBY_VERSION =~ /(\d+.\d+)/
  require "#{$1}/rocketamf_ext"
rescue LoadError
  require 'rocketamf_ext'
end

module RocketAMF
  # This module holds all the modules/classes that implement AMF's functionality
  # in C
  module Ext
    $DEBUG and warn 'Using C library for RocketAMF.'
  end

  #:stopdoc:
  # Import serializer/deserializer
  Deserializer = RocketAMF::Ext::Deserializer
  Serializer = RocketAMF::Ext::Serializer

  #:startdoc:
end