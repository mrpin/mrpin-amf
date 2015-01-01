$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
$:.unshift "#{File.expand_path(File.dirname(__FILE__))}/rocketamf/"
$:.unshift "#{File.expand_path(File.dirname(__FILE__))}/rocketamf/types/"

require 'date'
require 'stringio'
require 'rocketamf/errors'
require 'rocketamf/extensions'
require 'rocketamf/mapping/class_mapping'
require 'rocketamf/constants'
require 'rocketamf/types'


#todo: implement C version
# begin
#   require 'rocketamf/ext'
# rescue LoadError

require 'rocketamf/pure'
# end

# MrPin RocketAMF is a full featured AMF3 serializer and deserializer with support for
# bi-directional Flash to Ruby class mapping, custom serialization and mapping,
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
#todo:change benchmark
#   # 100000 objects
#   # Ruby 1.8
#   Testing native AMF3:
#     minimum serialize time: 1.444652s
#     minimum deserialize time: 0.879407s
#   Testing pure AMF3:
#     minimum serialize time: 31.637864s
#     minimum deserialize time: 14.773969s
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
# If you wish to send and receive IExternalizable objects, you will need to
# implement <tt>encode_amf</tt>, <tt>read_external</tt>, and <tt>write_external</tt>.
# Below is an example of a ResultSet class that extends Array and serializes as
# an array collection. RocketAMF can automatically serialize arrays as
# ArrayCollection objects, so this is just an example of how you might implement
# an object that conforms to IExternalizable.
#
# Example:
#
#   class ResultSet < Array
#     def encode_amf ser
#         # Serialize as an ArrayCollection object
#         # It conforms to IExternalizable, does not have any dynamic properties,
#         # and has no "sealed" members. See the AMF3 specs for more details about
#         # object traits.
#         ser.write_object self, nil, {
#           :class_name => "flex.messaging.io.ArrayCollection",
#           :externalizable => true,
#           :dynamic => false,
#           :members => []
#         }
#     end
#   
#     # Write self as array to stream
#     def write_external ser
#       ser.write_array(self)
#     end
#   
#     # Read array out and replace data with deserialized array.
#     def read_external des
#       replace(des.read_object)
#     end
#   end
module RocketAMF

  #
  # Constants
  #

  #todo: use c version
  CLASS_MAPPER = RocketAMF::ClassMapping

  #
  # Static methods
  #

  # Deserialize the AMF string _source_ of the given AMF version into a Ruby
  # data structure and return it. Creates an instance of <tt>RocketAMF::Deserializer</tt>
  # with a new instance of <tt>RocketAMF::CLASS_MAPPER</tt> and calls deserialize
  # on it with the given source, returning the result.
  def self.deserialize(source)
    deserializer = RocketAMF::Deserializer.new(RocketAMF::CLASS_MAPPER.new)
    deserializer.deserialize(source)
  end

  # Serialize the given Ruby data structure _obj_ into an AMF stream using the
  # given AMF version. Creates an instance of <tt>RocketAMF::Serializer</tt>
  # with a new instance of <tt>RocketAMF::CLASS_MAPPER</tt> and calls serialize
  # on it with the given object, returning the result.
  def self.serialize(obj)
    serializer = RocketAMF::Serializer.new(RocketAMF::CLASS_MAPPER.new)
    serializer.serialize(obj)
  end


end