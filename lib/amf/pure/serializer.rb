module AMF
  module Pure
    # Pure ruby serializer for AMF3
    class Serializer

      #
      # Modules
      #

      private
      include AMF::Pure::IOHelperWrite

      #
      # Properties
      #

      #
      # Methods
      #

      # Pass in the class mapper instance to use when serializing. This enables
      # better caching behavior in the class mapper and allows one to change
      # mappings between serialization attempts.
      public
      def initialize(class_mapper)
        @class_mapper = class_mapper
        @stream       = ''
        @depth        = 0
      end

      # Serialize the given object using AMF3. Can be called from inside
      # encode_amf.
      def serialize(obj)
        # Initialize caches
        if @depth == 0
          @cache_strings = CacheStrings.new
          @cache_objects = CacheObjects.new
          @cache_traits  = CacheStrings.new
        end
        @depth += 1

        # Perform serialization
        amf3_serialize(obj)

        # Cleanup
        @depth -= 1
        if @depth == 0
          @cache_strings = nil
          @cache_objects = nil
          @cache_traits  = nil
        end

        @stream
      end

      private
      def amf3_serialize(object)
        case true
          when object.respond_to?(:encode_amf)
            object.encode_amf(self)
          when object.is_a?(NilClass)
            amf3_write_null
          when object.is_a?(TrueClass)
            amf3_write_true
          when object.is_a?(FalseClass)
            amf3_write_false
          when object.is_a?(Numeric)
            amf3_write_numeric(object)
          when object.is_a?(Symbol), object.is_a?(String)
            amf3_write_string(object.to_s)
          when object.is_a?(Time)
            amf3_write_time object
          when object.is_a?(Date)
            amf3_write_date(object)
          when object.is_a?(StringIO)
            amf3_write_byte_array(object)
          when object.is_a?(Array)
            amf3_write_array(object)
          when object.is_a?(Hash), object.is_a?(Object)
            amf3_write_object(object)
          else
            raise AMFError, 'unknown type for serialize'
        end
      end

      # Helper for writing arrays inside encode_amf.
      public
      def write_array(value)
        amf3_write_array(value)
      end

      # Helper for writing objects inside encode_amf. If you pass in a property hash, it will use
      # it rather than having the class mapper determine properties.
      # You can also specify a traits hash, which can be used to reduce serialized
      # data size or serialize things as externalizable.
      public
      def write_object(obj, props = nil, traits = nil)
        amf3_write_object(obj, props, traits)
      end

      private
      def amf3_write_null
        # no data is serialized except their type marker
        @stream << AMF3_NULL_MARKER
      end

      private
      def amf3_write_reference(index)
        header = index << 1 # shift value left to leave a low bit of 0
        @stream << pack_integer(header)
      end


      private
      def amf3_write_true
        # no data is serialized except their type marker
        @stream << AMF3_TRUE_MARKER
      end

      private
      def amf3_write_false
        # no data is serialized except their type marker
        @stream << AMF3_FALSE_MARKER
      end

      private
      def amf3_write_numeric(value)
        if !value.integer? || value < MIN_INTEGER || value > MAX_INTEGER # Check valid range for 29 bits
          @stream << AMF3_DOUBLE_MARKER
          @stream << pack_double(value)
        else
          @stream << AMF3_INTEGER_MARKER
          @stream << pack_integer(value)
        end
      end

      private
      def amf3_write_time(value)
        @stream << AMF3_DATE_MARKER

        if @cache_objects[value] != nil
          amf3_write_reference(@cache_objects[value])
        else
          # Cache time
          @cache_objects.add_object(value)

          # Build AMF string
          value = value.getutc # Dup and convert to UTC
          milli = (value.to_f * 1000).to_i
          @stream << AMF3_NULL_MARKER
          @stream << pack_double(milli)
        end
      end

      private
      def amf3_write_date(value)
        @stream << AMF3_DATE_MARKER

        if @cache_objects[value] != nil
          amf3_write_reference(@cache_objects[value])
        else
          # Cache date
          @cache_objects.add_object(value)

          # Build AMF string
          @stream << AMF3_NULL_MARKER
          @stream << pack_double(value.strftime('%Q').to_i)
        end
      end

      private
      def amf3_write_byte_array(value)
        @stream << AMF3_BYTE_ARRAY_MARKER

        if @cache_objects[value] != nil
          amf3_write_reference(@cache_objects[value])
        else
          @cache_objects.add_object(value)
          str = value.string
          @stream << pack_integer(str.bytesize << 1 | 1)
          @stream << str
        end
      end

      private
      def amf3_write_array(value)
        # Write type marker
        @stream << AMF3_ARRAY_MARKER

        # Write reference or cache array
        if @cache_objects[value] != nil
          amf3_write_reference(@cache_objects[value])
          return
        else
          @cache_objects.add_object(value)
        end

        # Build AMF string for array
        header = value.length << 1 # make room for a low bit of 1
        header = header | 1 # set the low bit to 1
        @stream << pack_integer(header)
        @stream << AMF3_CLOSE_DYNAMIC_ARRAY
        value.each do |elem|
          amf3_serialize elem
        end
      end

      private
      def amf3_write_object(value, properties = nil, traits = nil)
        @stream << AMF3_OBJECT_MARKER

        # Caching...
        if @cache_objects[value] != nil
          amf3_write_reference(@cache_objects[value])
          return
        end

        @cache_objects.add_object(value)

        # Calculate traits if not given
        is_default = false
        if traits.nil?
          traits     =
              {
                  class_name: @class_mapper.get_class_name_remote(value),
                  members:    [],
                  dynamic:    true
              }
          is_default = true unless traits[:class_name]
        end

        class_name = is_default ? '__default__' : traits[:class_name]

        # Write out traits
        if class_name && @cache_traits[class_name] != nil
          @stream << pack_integer(@cache_traits[class_name] << 2 | 0x01)
        else
          @cache_traits.add_string(class_name) if class_name

          # Write out trait header
          header = 0x03 # Not object ref and not trait ref
          header |= 0x02 << 2 if traits[:dynamic]
          header |= traits[:members].length << 4
          @stream << pack_integer(header)

          # Write out class name
          if class_name == '__default__'
            amf3_write_string_internal('')
          else
            amf3_write_string_internal(class_name.to_s)
          end

          # Write out members
          traits[:members].each { |m| amf3_write_string_internal(m) }
        end

        # Extract properties if not given
        properties = @class_mapper.object_serialize(value) if properties.nil?

        # Write out sealed properties
        traits[:members].each do |m|
          amf3_serialize(properties[m])
          properties.delete(m)
        end

        # Write out dynamic properties
        if traits[:dynamic]
          # Write out dynamic properties
          properties.each do |key, val|
            amf3_write_string_internal(key.to_s)
            amf3_serialize(val)
          end

          # Write close
          @stream << AMF3_CLOSE_DYNAMIC_OBJECT
        end
      end

      private
      def amf3_write_string(value)
        @stream << AMF3_STRING_MARKER
        amf3_write_string_internal value
      end


      private
      def amf3_write_string_internal(value)
        if value.respond_to?(:encode)
          value = value.dup if value.frozen?

          value = value.encode('UTF-8')

          value.force_encoding('ASCII-8BIT')
        end

        if value == ''
          @stream << AMF3_EMPTY_STRING
        elsif @cache_strings[value] != nil
          amf3_write_reference(@cache_strings[value])
        else


          # Cache string
          @cache_strings.add_string(value)

          # Build AMF string
          @stream << pack_integer(value.bytesize << 1 | 1)
          @stream << value
        end
      end

    end # Serializer

  end #Pure
end #AMF
