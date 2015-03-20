$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
$:.unshift "#{File.expand_path(File.dirname(__FILE__))}/tamf/"
$:.unshift "#{File.expand_path(File.dirname(__FILE__))}/amf/types/"

require 'date'
require 'stringio'
require 'amf/common/hash_with_type'
require 'amf/pure/errors/all_files'
require 'amf/pure/helpers/all_files'
require 'amf/pure/mapping/class_mapper'


#todo: implement C version
# begin
#   require 'rocketamf/ext'
# rescue LoadError

require 'amf/pure'
# end

# AMF is a full featured AMF3 serializer/deserializer with support for
# bi-directional other language to ruby class mapping, custom serialization and mapping,
# remoting gateway helpers that follow AMF3 messaging specs, and a suite of specs
# to ensure adherence to the specification documents put out by Adobe. If the C
# components compile, then RocketAMF automatically takes advantage of them to
# provide a substantial performance benefit. In addition, RocketAMF is fully
# compatible with Ruby 2.0, 2.1.
#
# == Performance
#
# RocketAMF provides native C extensions for serialization, deserialization,
# remoting, and class mapping. If your environment supports them, RocketAMF will
# automatically take advantage of the C serializer, deserializer, and remoting
# support. The C class mapper has some substantial performance optimizations that
# make it incompatible with the pure Ruby class mapper, and so it must be manually
# enabled. For more information see <tt>RocketAMF::ClassMapping</tt>. Below are
# some benchmarks I took using using a simple little benchmarking utility I whipped
# up, which can be found in the root of the repository.
#
#   # 100000 objects
#   # Ruby 2.0
#todo:update native benchmark
#   Testing native AMF3:
#     minimum serialize time: 1.444652s
#     minimum deserialize time: 0.879407s
#   Testing pure AMF3:
#     minimum serialize time: 49.294496s
#     minimum deserialize time: 6.600238s
#
# == Serialization & Deserialization
#
# RocketAMF provides two main methods - <tt>serialize</tt> and <tt>deserialize</tt>.
# Deserialization takes a String or StringIO object and the AMF version if different
# from the default. Serialization takes any Ruby object and the version if different
# from the default. AMF3  not sending duplicate data.
#
# == Mapping Classes Between Flash and Ruby
#
# RocketAMF provides a simple class mapping tool to facilitate serialization and
# deserialization of typed objects. Refer to the documentation of
# <tt>RocketAMF::ClassMapping</tt> for more details. If the provided class
# mapping tool is not sufficient for your needs, you also have the option to
# replace it with a class mapper of your own devising that matches the documented
# API.
#
# == Advanced Serialization (encode_amf and IExternalizable)
#
# RocketAMF provides some additional functionality to support advanced
# serialization techniques. If you define an <tt>encode_amf</tt> method on your
# object, it will get called during serialization. It is passed a single argument,
# the serializer, and it can use the serializer stream, the <tt>serialize</tt>
# method, the <tt>write_array</tt> method, the <tt>write_object</tt> method, and
# the serializer version. Below is a simple example that uses <tt>write_object</tt>
# to customize the property hash that is used for serialization.
#
# Example:
#
#   class TestObject
#     def encode_amf ser
#       ser.write_object self, @attributes
#     end
#   end
#
# If you plan on using the <tt>serialize</tt> method, make sure to pass in the
# current serializer version, or you could create a message that cannot be deserialized.
#
# Example:
#
#   class VariableObject
#     def encode_amf ser
#         ser.serialize(false)
#     end
#   end
#
module AMF

  class << self


    attr_accessor :class_mapper

    # Deserialize the AMF string _source_ of the given AMF version into a Ruby
    # data structure and return it. Creates an instance of <tt>RocketAMF::Deserializer</tt>
    # with a new instance of <tt>RocketAMF::CLASS_MAPPER</tt> and calls deserialize
    # on it with the given source, returning the result.
    def deserialize(source)
      deserializer = AMF::Deserializer.new(class_mapper.new)
      deserializer.deserialize(source)
    end

    # Serialize the given Ruby data structure _obj_ into an AMF stream using the
    # given AMF version. Creates an instance of <tt>RocketAMF::Serializer</tt>
    # with a new instance of <tt>RocketAMF::CLASS_MAPPER</tt> and calls serialize
    # on it with the given object, returning the result.
    def serialize(obj)
      serializer = AMF::Serializer.new(class_mapper.new)
      serializer.serialize(obj)
    end
  end



  #todo: use c version
  # Activating the C Class Mapper:
  #   require 'rubygems'
  #   require 'amf'
  #   AMF::ClassMapper = AMF::Ext::FastClassMapping

  self.class_mapper = AMF::ClassMapper

end
