require 'rocketamf/pure/helpers/io_helper_write'
require 'rocketamf/pure/helpers/object_cache'
require 'rocketamf/pure/helpers/string_cache'

module RocketAMF
  module Pure
    # Pure ruby serializer for AMF3
    class Serializer

      #
      # Modules
      #

      private
      include RocketAMF::Pure::IOHelperWrite

      #
      # Properties
      #

      public
      attr_reader :stream

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
          @string_cache = StringCache.new
          @object_cache = ObjectCache.new
          @trait_cache  = StringCache.new
        end
        @depth += 1

        # Perform serialization
        amf3_serialize(obj)

        # Cleanup
        @depth -= 1
        if @depth == 0
          @ref_cache    = nil
          @string_cache = nil
          @object_cache = nil
          @trait_cache  = nil
        end

        @stream
      end

      # Helper for writing arrays inside encode_amf.
      def write_array(value)
        amf3_write_array value
      end

      # Helper for writing objects inside encode_amf. If you pass in a property hash, it will use
      # it rather than having the class mapper determine properties.
      # You can also specify a traits hash, which can be used to reduce serialized
      # data size or serialize things as externalizable.
      def write_object(obj, props = nil, traits = nil)
        amf3_write_object(obj, props, traits)
      end


      private
      def amf3_serialize(obj)
        if obj.respond_to?(:encode_amf)
          obj.encode_amf(self)
        elsif obj.is_a?(NilClass)
          amf3_write_null
        elsif obj.is_a?(TrueClass)
          amf3_write_true
        elsif obj.is_a?(FalseClass)
          amf3_write_false
        elsif obj.is_a?(Numeric)
          amf3_write_numeric(obj)
        elsif obj.is_a?(Symbol) || obj.is_a?(String)
          amf3_write_string(obj.to_s)
        elsif obj.is_a?(Time)
          amf3_write_time obj
        elsif obj.is_a?(Date)
          amf3_write_date(obj)
        elsif obj.is_a?(StringIO)
          amf3_write_byte_array(obj)
        elsif obj.is_a?(Array)
          amf3_write_array(obj)
        elsif obj.is_a?(Hash) || obj.is_a?(Object)
          amf3_write_object(obj)
        end
      end

      private
      def amf3_write_reference(index)
        header = index << 1 # shift value left to leave a low bit of 0
        @stream << pack_integer(header)
      end

      private
      def amf3_write_null
        @stream << AMF3_NULL_MARKER
      end

      private
      def amf3_write_true
        @stream << AMF3_TRUE_MARKER
      end

      private
      def amf3_write_false
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
      def amf3_write_string(value)
        @stream << AMF3_STRING_MARKER
        amf3_write_utf8_vr value
      end

      private
      def amf3_write_time(value)
        @stream << AMF3_DATE_MARKER

        if @object_cache[value] != nil
          amf3_write_reference(@object_cache[value])
        else
          # Cache time
          @object_cache.add_obj(value)

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

        if @object_cache[value] != nil
          amf3_write_reference(@object_cache[value])
        else
          # Cache date
          @object_cache.add_obj(value)

          # Build AMF string
          @stream << AMF3_NULL_MARKER
          @stream << pack_double(value.strftime('%Q').to_i)
        end
      end

      private
      def amf3_write_byte_array(value)
        @stream << AMF3_BYTE_ARRAY_MARKER

        if @object_cache[value] != nil
          amf3_write_reference(@object_cache[value])
        else
          @object_cache.add_obj(value)
          str = value.string
          @stream << pack_integer(str.bytesize << 1 | 1)
          @stream << str
        end
      end

      private
      def amf3_write_array(value)
        # Is it an array collection?
        is_array_collection = false

        if value.respond_to?(:is_array_collection?)
          is_array_collection = value.is_array_collection?
        else
          is_array_collection = @class_mapper.use_array_collection
        end

        # Write type marker
        @stream << (is_array_collection ? AMF3_OBJECT_MARKER : AMF3_ARRAY_MARKER)

        # Write reference or cache array
        if @object_cache[value] != nil
          amf3_write_reference(@object_cache[value])
          return
        else
          @object_cache.add_obj(value)
          @object_cache.add_obj(nil) if is_array_collection # The array collection source array
        end

        # Write out traits and array marker if it's an array collection
        if is_array_collection
          class_name = 'flex.messaging.io.ArrayCollection'

          if @trait_cache[class_name] != nil
            @stream << pack_integer(@trait_cache[class_name] << 2 | 0x01)
          else
            @trait_cache.add_obj(class_name)
            @stream << "\a" # Externalizable, non-dynamic
            amf3_write_utf8_vr(class_name)
          end
          @stream << AMF3_ARRAY_MARKER
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
      def amf3_write_object(obj, properties = nil, traits = nil)
        @stream << AMF3_OBJECT_MARKER

        # Caching...
        if @object_cache[obj] != nil
          amf3_write_reference(@object_cache[obj])
          return
        end

        @object_cache.add_obj(obj)

        # Calculate traits if not given
        is_default = false
        if traits.nil?
          traits     =
              {
                  class_name:     @class_mapper.get_as_class_name(obj),
                  members:        [],
                  externalizable: false,
                  dynamic:        true
              }
          is_default = true unless traits[:class_name]
        end

        class_name = is_default ? '__default__' : traits[:class_name]

        # Write out traits
        if class_name && @trait_cache[class_name] != nil
          @stream << pack_integer(@trait_cache[class_name] << 2 | 0x01)
        else
          @trait_cache.add_obj(class_name) if class_name

          # Write out trait header
          header = 0x03 # Not object ref and not trait ref
          header |= 0x02 << 2 if traits[:dynamic]
          header |= 0x01 << 2 if traits[:externalizable]
          header |= traits[:members].length << 4
          @stream << pack_integer(header)

          # Write out class name
          if class_name == '__default__'
            amf3_write_utf8_vr('')
          else
            amf3_write_utf8_vr(class_name.to_s)
          end

          # Write out members
          traits[:members].each { |m| amf3_write_utf8_vr(m) }
        end

        # If externalizable, take externalized data shortcut
        if traits[:externalizable]
          obj.write_external(self)
          return
        end

        # Extract properties if not given
        properties = @class_mapper.props_for_serialization(obj) if properties.nil?

        # Write out sealed properties
        traits[:members].each do |m|
          amf3_serialize(properties[m])
          properties.delete(m)
        end

        # Write out dynamic properties
        if traits[:dynamic]
          # Write out dynamic properties
          properties.sort.each do |key, val| # Sort props until Ruby 1.9 becomes common
            amf3_write_utf8_vr(key.to_s)
            amf3_serialize(val)
          end

          # Write close
          @stream << AMF3_CLOSE_DYNAMIC_OBJECT
        end
      end

      private
      def amf3_write_utf8_vr(value, encode = true)
        if value.respond_to?(:encode)
          if encode
            value = value.encode('UTF-8')
          else
            value = value.dup if value.frozen?
          end
          value.force_encoding('ASCII-8BIT')
        end

        if value == ''
          @stream << AMF3_EMPTY_STRING
        elsif @string_cache[value] != nil
          amf3_write_reference(@string_cache[value])
        else
          # Cache string
          @string_cache.add_obj(value)

          # Build AMF string
          @stream << pack_integer(value.bytesize << 1 | 1)
          @stream << value
        end
      end

    end # Serializer

  end #Pure
end #RocketAMF
