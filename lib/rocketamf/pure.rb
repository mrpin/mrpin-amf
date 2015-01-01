require 'rocketamf/pure/deserializer'
require 'rocketamf/pure/serializer'

module RocketAMF
  # This module holds all the modules/classes that implement AMF's functionality
  # in pure ruby
  module Pure
    $DEBUG and warn 'Using pure library for RocketAMF.'
  end

  #:stopdoc:
  # Import serializer/deserializer
  Deserializer = RocketAMF::Pure::Deserializer
  Serializer = RocketAMF::Pure::Serializer
  #:startdoc:
end