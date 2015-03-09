begin
  # Fat binaries for Windows
  RUBY_VERSION =~ /(\d+.\d+)/
  require "#{$1}/rocketamf_ext"
rescue LoadError
  require 'rocketamf_ext'
end

module AMF
  # This module holds all the modules/classes that implement AMF's functionality
  # in C
  module Ext
    $DEBUG and warn 'Using C library for AMF.'
  end

  #:stopdoc:
  # Import serializer/deserializer
  Deserializer = AMF::Ext::Deserializer
  Serializer = AMF::Ext::Serializer

  #:startdoc:
end