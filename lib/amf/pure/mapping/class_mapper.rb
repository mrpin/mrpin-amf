require 'amf/pure/mapping/mapping_set'

module AMF

  # Handles class name mapping between other language and ruby and assists in
  # serializing and deserializing data between them. Simply map an other-language class to a
  # ruby class and when the object is (de)serialized it will end up as the
  # appropriate class.
  #
  # Example:
  #
  #   AMF.class_mapper.register_class_alias('SomeClass', 'RubyClass')
  #
  # == C ClassMapper
  #
  # The C class mapper, <tt>AMF::Ext::FastClassMapping</tt>, has the same
  # public API that <tt>AMF::ClassMapper</tt> does, but has some additional
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

  class ClassMapper

    class << self

      attr_reader :map

      #
      # Methods
      #

      public
      def initialize
        @map = MappingSet.new
      end

      public
      def register_class_alias(class_local, class_remote)
        @map.register_class_alias(class_local, class_remote)
      end

      public
      def register_classes(map)
        map.each do |class_local, class_remote|
          self.register_class_alias(class_local, class_remote)
        end
      end

      # Reset all class mappings except the defaults
      public
      def reset
        @map = MappingSet.new
        nil
      end
    end #end of static

    # init static
    self.initialize

    #
    # Methods
    #

    public
    def initialize
      #cache static variable
      @map = ClassMapper.map
    end

    # Returns the other-language class name for the given ruby object.
    public
    def get_class_name_remote(object)
      # Get class name
      if object.is_a?(HashWithType)
        ruby_class_name = object.class_type
      elsif object.is_a?(Hash)
        return nil
      else
        ruby_class_name = object.class.name
      end

      # Get mapped remote class name
      @map.get_class_name_remote(ruby_class_name)
    end

    # Instantiates a ruby object using the mapping configuration based on the
    # source ActionScript class name. If there is no mapping defined, it returns
    # a <tt>AMF::HashWithType</tt> with the serialized class name.
    public
    def create_object(class_name_remote)
      result = nil

      if class_name_remote.nil? || class_name_remote.empty?
        return {}
      end

      class_name_local = @map.get_class_name_local(class_name_remote)

      if class_name_local.nil?
        # Populate a simple hash, since no mapping
        result = HashWithType.new(class_name_remote)
      else
        ruby_class = class_name_local.split('::').inject(Kernel) { |scope, const_name| scope.const_get(const_name) }
        result     = ruby_class.new
      end

      result
    end

    # Populates the ruby object using the given properties. props will be hashes with symbols for keys.
    public
    def object_deserialize(target, props)
      # Don't even bother checking if it responds to setter methods if it's a TypedHash
      if target.is_a?(HashWithType)
        target.merge! props
        return target
      end

      # Some type of object
      hash_like = target.respond_to?('[]=')

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
    def object_serialize(ruby_obj)
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