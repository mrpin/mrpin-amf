$:.unshift(File.dirname(__FILE__) + '/ext')
$:.unshift(File.dirname(__FILE__) + '/lib')
require 'rubygems'
require 'amf'
require 'amf/pure/deserializer' # Only ext gets included by default if available
require 'amf/pure/serializer'

OBJECT_COUNT = 100000
TESTS        = 5

class TestClass
  attr_accessor :prop_a
  attr_accessor :prop_b
  attr_accessor :prop_c
  attr_accessor :prop_d
  attr_accessor :prop_e

  def populate(some_arg = nil) # Make sure class mapper doesn't think populate is a property
    @@count ||= 1
    @prop_a = "asdfasdf #{@@count}"
    @prop_b = 'simple string'
    @prop_c = 3120094.03
    @prop_d = Time.now
    @prop_e = 3120094
    @@count += 1
    self
  end
end

objs = []
OBJECT_COUNT.times do
  objs << TestClass.new.populate
end

#todo: add native
%w( pure).each do |type|

  use_ruby_version = type == 'pure'

  # Set up class mapper
  class_mapper     = nil

  if use_ruby_version
    class_mapper = AMF::ClassMapper
  else
    class_mapper = AMF::Ext::FastClassMapping
  end

  class_mapper.define do |m|
    m.map as: 'TestClass', ruby: 'TestClass'
  end


  # 2**24 is larger than anyone is ever going to run this for
  min_serialize   = 2**24
  min_deserialize = 2**24

  puts "Testing #{type} AMF3"
  TESTS.times do
    serializer   = nil
    deserializer = nil

    if use_ruby_version
      serializer   = AMF::Pure::Serializer.new(class_mapper.new)
      deserializer = AMF::Pure::Deserializer.new(class_mapper.new)
    else
      serializer   = AMF::Ext::Serializer.new(class_mapper.new)
      deserializer = AMF::Ext::Deserializer.new(class_mapper.new)
    end

    start_time = Time.now
    out        = serializer.serialize(objs)
    end_time   = Time.now
    puts "\tserialize run: #{end_time-start_time}s"
    min_serialize = [end_time-start_time, min_serialize].min

    start_time = Time.now
    temp       = deserializer.deserialize(out)
    end_time   = Time.now
    puts "\tdeserialize run: #{end_time-start_time}s"
    min_deserialize = [end_time-start_time, min_deserialize].min
  end

  puts "\tminimum serialize time: #{min_serialize}s"
  puts "\tminimum deserialize time: #{min_deserialize}s"
end