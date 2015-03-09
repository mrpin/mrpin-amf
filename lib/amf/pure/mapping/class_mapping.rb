require 'amf/pure/mapping/mapping_set'

module AMF

  # Handles class name mapping between AS and ruby and assists in
  # serializing and deserializing data between them. Simply map an AS class to a
  # ruby class and when the object is (de)serialized it will end up as the
  # appropriate class.
  #
  # Example:
  #
  #   AMF::CLASS_MAPPER.define do |m|
  #     m.map as: 'AsClass', ruby: 'RubyClass'
  #     m.map as: 'vo.User', ruby: 'Model::User'
  #   end
  #
  # == Object Population/Serialization
  #
  # In addition to handling class name mapping, it also provides helper methods
  # for populating ruby objects from AMF and extracting properties from ruby objects
  # for serialization. Support for hash-like objects and objects using
  # <tt>attr_accessor</tt> for properties is currently built in, but custom classes
  # may require subclassing the class mapper to add support.
  #
  # == Complete Replacement
  #
  # In some cases, it may be beneficial to replace the default provider of class
  # mapping completely. In this case, simply assign your class mapper class to
  # <tt>AMF::CLASS_MAPPER</tt> after loading gem. Through the magic of
  # <tt>const_missing</tt>, <tt>CLASS_MAPPER</tt> is only defined after the first
  # access by default, so you get no annoying warning messages. Custom class mappers
  # must implement the following methods on instances: <tt>use_array_collection</tt>,
  # <tt>get_as_class_name</tt>, <tt>get_ruby_obj</tt>, <tt>populate_ruby_obj</tt>,
  # and <tt>props_for_serialization</tt>. In addition, it should have a class level
  # <tt>mappings</tt> method that returns the mapping set it's using, although its
  # not required. If you'd like to see an example of what complete replacement
  # offers, check out RubyAMF (http://github.com/rubyamf/rubyamf).
  #
  # Example:
  #
  #   require 'rubygems'
  #   require 'amf'
  #
  #   AMF.const_set(CLASS_MAPPER, MyCustomClassMapper)
  #
  # == C ClassMapper
  #
  # The C class mapper, <tt>AMF::Ext::FastClassMapping</tt>, has the same
  # public API that <tt>RubyAMF::ClassMapping</tt> does, but has some additional
  # performance optimizations that may interfere with the proper serialization of
  # objects. To reduce the cost of processing public methods for every object,
  # its implementation of <tt>props_for_serialization</tt> caches valid properties
  # by class, using the class as the hash key for property lookup. This means that
  # adding and removing properties from instances while serializing using a given
  # class mapper instance will result in the changes not being detected.  As such,
  # it's not enabled by default. So long as you aren't planning on modifying
  # classes during serialization using <tt>encode_amf</tt>, the faster C class
  # mapper should be perfectly safe to use.
  #
  # Activating the C Class Mapper:
  #
  #   require 'rubygems'
  #   require 'amf'
  #todo:review
  #   AMF::ClassMapper = AMF::Ext::FastClassMapping
  class ClassMapping
    class << self
      # Returns the mapping set with all the class mappings that is currently
      # being used.
      def mappings
        @mappings ||= MappingSet.new
      end

      # Define class mappings in the block. Block is passed a <tt>MappingSet</tt> object
      # as the first parameter.
      #
      # Example:
      #
      #   AMF::CLASS_MAPPER.define do |m|
      #     m.map as: 'AsClass', ruby: 'RubyClass'
      #   end
      def define(&block) #:yields: mapping_set
        yield mappings
      end

      # Reset all class mappings except the defaults and return
      def reset
        @mappings             = nil
      end
    end

    #
    # Properties
    #

    #
    # Methods
    #

    # Copies configuration from class level configs to populate object
    public
    def initialize
      @mappings             = self.class.mappings
    end

    # Returns the ActionScript class name for the given ruby object. Will also
    # take a string containing the ruby class name.
    def get_as_class_name(obj)
      # Get class name
      if obj.is_a?(String)
        ruby_class_name = obj
      elsif obj.is_a?(Types::TypedHash)
        ruby_class_name = obj.type
      elsif obj.is_a?(Hash)
        return nil
      else
        ruby_class_name = obj.class.name
      end

      # Get mapped AS class name
      @mappings.get_as_class_name(ruby_class_name)
    end

    # Instantiates a ruby object using the mapping configuration based on the
    # source ActionScript class name. If there is no mapping defined, it returns
    # a <tt>AMF::Types::TypedHash</tt> with the serialized class name.
    public
    def get_ruby_obj(as_class_name)
      result = nil

      ruby_class_name = @mappings.get_ruby_class_name(as_class_name)
      if ruby_class_name.nil?
        # Populate a simple hash, since no mapping
        result = Types::TypedHash.new(as_class_name)
      else
        ruby_class = ruby_class_name.split('::').inject(Kernel) { |scope, const_name| scope.const_get(const_name) }
        result     = ruby_class.new
      end

      result
    end

    # Populates the ruby object using the given properties. props will be hashes with symbols for keys.
    public
    def populate_ruby_obj(target, props)

      # Don't even bother checking if it responds to setter methods if it's a TypedHash
      if target.is_a?(Types::TypedHash)
        target.merge! props
        return target
      end

      # Some type of object
      hash_like = target.respond_to?("[]=")
      props.each do |key, value|
        if target.respond_to?("#{key}=")
          target.send("#{key}=", value)
        elsif hash_like
          target[key] = value
        end
      end

      target
    end

    # Extracts all exportable properties from the given ruby object and returns
    # them in a hash. If overriding, make sure to return a hash wth string keys
    # unless you are only going to be using the native C extensions, as the pure
    # ruby serializer performs a sort on the keys to acheive consistent, testable
    # results.
    public
    def props_for_serialization(ruby_obj)
      result = {}

      # Handle hashes
      if ruby_obj.is_a?(Hash)

        # Stringify keys to make it easier later on and allow sorting
        ruby_obj.each { |k, v| result[k.to_s] = v }

      else

        # Generic object serializer
        @ignored_props ||= Object.new.public_methods
        (ruby_obj.public_methods - @ignored_props).each do |method_name|
          # Add them to the prop hash if they take no arguments
          method_def               = ruby_obj.method(method_name)
          result[method_name.to_s] = ruby_obj.send(method_name) if method_def.arity == 0
        end
      end

      result
    end # props_for_serialization
  end #ClassMapping
end #AMF