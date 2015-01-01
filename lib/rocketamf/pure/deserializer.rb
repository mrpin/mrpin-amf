require 'rocketamf/pure/helpers/io_helper_read'

module RocketAMF
  module Pure
    # Pure ruby deserializer for AMF3 requests
    class Deserializer

      #
      # Modules
      #
      private
      include RocketAMF::Pure::IOHelperRead

      #
      # Properties
      #

      public
      attr_reader :source

      # Pass in the class mapper instance to use when deserializing. This
      # enables better caching behavior in the class mapper and allows
      # one to change mappings between deserialization attempts.
      public
      def initialize(class_mapper)
        @class_mapper = class_mapper
      end

      # Deserialize the source using AMF3. Source should either
      # be a string or StringIO object. If you pass a StringIO object,
      # it will have its position updated to the end of the deserialized
      # data.
      # raise AMFError if error appeared in deserialize, source is nil
      # return hash {requests: [], incomplete_request: String}
      public
      def deserialize(source)
        raise AMFError, 'no source to deserialize' if source.nil?

        @source = source.is_a?(StringIO) ? source : StringIO.new(source)

        requests = []

        incomplete_request = nil

        until @source.eof?
          begin
            @string_cache = []
            @object_cache = []
            @trait_cache  = []

            @position_request_read = @source.pos

            requests << amf3_deserialize
          rescue AMFErrorIncomplete => e
            @source.pos = @position_request_read

            incomplete_request = @source.read

            break
          end
        end

        {
            requests:           requests,
            incomplete_request: incomplete_request
        }
      end

      # Reads an object from the deserializer stream and returns it.
      public
      def read_object
        amf3_deserialize
      end

      private
      def amf3_deserialize
        type = read_int8(@source)
        case type
          when AMF3_UNDEFINED_MARKER
            nil
          when AMF3_NULL_MARKER
            nil
          when AMF3_FALSE_MARKER
            false
          when AMF3_TRUE_MARKER
            true
          when AMF3_INTEGER_MARKER
            amf3_read_integer
          when AMF3_DOUBLE_MARKER
            amf3_read_number
          when AMF3_STRING_MARKER
            amf3_read_string
          when AMF3_XML_DOC_MARKER, AMF3_XML_MARKER
            amf3_read_xml
          when AMF3_DATE_MARKER
            amf3_read_date
          when AMF3_ARRAY_MARKER
            amf3_read_array
          when AMF3_OBJECT_MARKER
            amf3_read_object
          when AMF3_BYTE_ARRAY_MARKER
            amf3_read_byte_array
          when AMF3_VECTOR_INT_MARKER, AMF3_VECTOR_UINT_MARKER, AMF3_VECTOR_DOUBLE_MARKER, AMF3_VECTOR_OBJECT_MARKER
            amf3_read_vector(type)
          when AMF3_DICT_MARKER
            amf3_read_dict
          else
            raise AMFError, "Invalid type: #{type}"
        end
      end

      private
      def get_as_reference_object(type)
        result = nil

        if (type & 0x01) == 0 #is reference?
          reference = type >> 1
          result    = @object_cache[reference]
        end

        result
      end

      private
      def get_as_reference_string(type)
        result = nil

        if (type & 0x01) == 0 #is reference?
          reference = type >> 1
          result    = @string_cache[reference]
        end

        result
      end

      private
      def amf3_read_integer
        result = 0

        n = 0
        b = read_word8(@source) || 0

        while (b & 0x80) != 0 && n < 3
          result = result << 7
          result = result | (b & 0x7f)
          b      = read_word8(@source) || 0
          n      = n + 1
        end

        if n < 3
          result = result << 7
          result = result | b
        else
          #Use all 8 bits from the 4th byte
          result = result << 8
          result = result | b

          #Check if the integer should be negative
          if result > MAX_INTEGER
            result -= (1 << 29)
          end
        end

        result
      end

      private
      def amf3_read_number
        result = read_double(@source)

        #check for NaN and convert them to nil
        if result.is_a?(Float) && result.nan?
          result = nil
        end

        result
      end

      private
      def amf3_read_string
        result = nil

        type = amf3_read_integer

        result = get_as_reference_string(type)

        if result.nil?
          length = type >> 1
          result = ''

          if length > 0

            if length > (@source.size - @source.pos)
              raise AMFErrorIncomplete.new
            end

            result = @source.read(length)
            result.force_encoding('UTF-8') if result.respond_to?(:force_encoding)
            @string_cache << result
          end
        end

        result
      end

      private
      def amf3_read_xml
        result = nil

        type = amf3_read_integer

        result = get_as_reference_object(type)

        if result.nil?
          length = type >> 1

          result = ''

          if length > 0
            if length > (@source.size - @source.pos)
              raise AMFErrorIncomplete.new
            end

            result = @source.read(length)
            result.force_encoding('UTF-8') if result.respond_to?(:force_encoding)
            @object_cache << result
          end
        end

        result
      end

      private
      def amf3_read_byte_array
        result = nil

        type = amf3_read_integer

        result = get_as_reference_object(type)

        if result.nil?
          length = type >> 1

          if length > (@source.size - @source.pos)
            raise AMFErrorIncomplete.new
          end

          result = StringIO.new(@source.read(length))
          @object_cache << result
        end

        result
      end

      private
      def amf3_read_array
        result = nil

        type = amf3_read_integer

        result = get_as_reference_object(type)

        if result.nil?
          length        = type >> 1
          property_name = amf3_read_string
          result        = property_name.length > 0 ? {} : []
          @object_cache << result

          while property_name.length > 0
            value                 = amf3_deserialize
            result[property_name] = value
            property_name         = amf3_read_string
          end

          0.upto(length - 1) { |i| result[i] = amf3_deserialize }
        end

        result
      end

      # externalizable - an instance of a Class that implements flash.utils.IExternalizable and completely controls the serialization of its members (no property names are included in the trait information)
      # dynamic - c an instance of a Class definition with the dynamic trait declared; public variable members can be added and removed from instances dynamically at runtime
      private
      def amf3_read_object
        result = nil

        type = amf3_read_integer

        result = get_as_reference_object(type)

        if result.nil?
          class_type         = type >> 1
          class_is_reference = (class_type & 0x01) == 0

          if class_is_reference
            reference = class_type >> 1
            traits    = @trait_cache[reference]
          else
            externalizable  = (class_type & 0x02) != 0
            dynamic         = (class_type & 0x04) != 0
            attribute_count = class_type >> 3
            class_name      = amf3_read_string

            class_attributes = []
            attribute_count.times { class_attributes << amf3_read_string } # Read class members

            traits =
                {
                    class_name:     class_name,
                    members:        class_attributes,
                    externalizable: externalizable,
                    dynamic:        dynamic
                }
            @trait_cache << traits
          end

          # Optimization for deserializing ArrayCollection
          if traits[:class_name] == 'flex.messaging.io.ArrayCollection'
            result = amf3_deserialize # Adds ArrayCollection array to object cache
            @object_cache << result # Add again for ArrayCollection source array
            return result
          end

          result = @class_mapper.get_ruby_obj(traits[:class_name])
          @object_cache << result

          if traits[:externalizable]
            result.read_external(self)
          else
            properties = {}

            traits[:members].each do |key|
              value           = amf3_deserialize
              properties[key] = value
            end

            if traits[:dynamic]
              while (key = amf3_read_string) && key.length != 0 do # read next key
                value           = amf3_deserialize
                properties[key] = value
              end
            end

            @class_mapper.populate_ruby_obj(result, properties)
          end

        end

        result
      end

      private
      def amf3_read_date
        result = nil

        type = amf3_read_integer

        result = get_as_reference_object(type)

        if result.nil?
          seconds = read_double(@source).to_f/1000
          result  = Time.at(seconds)
          @object_cache << result
        end

        result
      end

      private
      def amf3_read_dict
        result = nil

        type = amf3_read_integer

        result = get_as_reference_object(type)

        if result.nil?
          result = {}
          @object_cache << result
          length    = type >> 1
          weak_keys = read_int8(@source) # Ignore: Not supported in ruby

          0.upto(length - 1) do |i|
            result[amf3_deserialize] = amf3_deserialize
          end

        end

        result
      end

      private
      def amf3_read_vector(vector_type)
        result = nil

        type = amf3_read_integer

        result = get_as_reference_object(type)

        if result.nil?

          result = []
          @object_cache << result

          length       = type >> 1
          fixed_vector = read_int8(@source) # Ignore

          case vector_type
            when AMF3_VECTOR_INT_MARKER
              0.upto(length - 1) do |i|
                int = read_word32_network(@source)
                int = int - 2**32 if int > MAX_INTEGER
                result << int
              end
            when AMF3_VECTOR_UINT_MARKER
              0.upto(length - 1) do |i|
                result << read_word32_network(@source)
              end
            when AMF3_VECTOR_DOUBLE_MARKER
              0.upto(length - 1) do |i|
                result << amf3_read_number
              end
            when AMF3_VECTOR_OBJECT_MARKER
              vector_class = amf3_read_string # Ignore
              0.upto(length - 1) do |i|
                result << amf3_deserialize
              end
            else
              #do nothing
          end
        end #if

        result
      end #read_vector

    end #Deserializer
  end #Pure
end