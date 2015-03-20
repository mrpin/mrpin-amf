module AMF
  module Pure
    # Pure ruby deserializer for AMF3 requests
    class Deserializer

      #
      # Modules
      #
      private
      include AMF::Pure::IOHelperRead

      #
      # Properties
      #

      # Used for read_object
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
      # raise AMFErrorIncomplete if source is incomplete
      # return hash {objects: [], incomplete_objects: String}
      public
      def deserialize(source)
        raise AMFError, 'no source to deserialize' if source.nil?

        @source = source.is_a?(StringIO) ? source : StringIO.new(source)

        objects = []

        incomplete_objects = nil

        until @source.eof?
          begin
            @cache_strings = []
            @cache_objects = []
            @cache_traits  = []

            @position_request_read = @source.pos

            objects << amf3_deserialize
          rescue AMFErrorIncomplete => e
            @source.pos = @position_request_read

            incomplete_objects = @source.read

            break
          end
        end

        {
            objects:            objects,
            incomplete_objects: incomplete_objects
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
          when AMF3_DATE_MARKER
            amf3_read_date
          when AMF3_ARRAY_MARKER
            amf3_read_array
          when AMF3_OBJECT_MARKER
            amf3_read_object
          when AMF3_BYTE_ARRAY_MARKER
            amf3_read_byte_array
          when AMF3_VECTOR_INT_MARKER, AMF3_VECTOR_UINT_MARKER, AMF3_VECTOR_DOUBLE_MARKER, AMF3_VECTOR_OBJECT_MARKER, AMF3_XML_DOC_MARKER, AMF3_XML_MARKER
            raise AMFError, "Unsupported type: #{type}"
          when AMF3_DICT_MARKER
            amf3_read_dictionary
          else
            raise AMFError, "Invalid type: #{type}"
        end
      end

      private
      def get_as_reference_object(type)
        result = nil

        if (type & 0x01) == 0 #is reference?
          reference = type >> 1
          result    = @cache_objects[reference]
        end

        result
      end

      private
      def get_as_reference_string(type)
        result = nil

        if (type & 0x01) == 0 #is reference?
          reference = type >> 1
          result    = @cache_strings[reference]
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
            @cache_strings << result
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
          @cache_objects << result
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
          @cache_objects << result

          while property_name.length > 0
            value                 = amf3_deserialize
            result[property_name] = value
            property_name         = amf3_read_string
          end

          0.upto(length - 1) { |i| result[i] = amf3_deserialize }
        end

        result
      end

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
            traits    = @cache_traits[reference]
          else
            dynamic         = (class_type & 0x04) != 0
            attribute_count = class_type >> 3
            class_name      = amf3_read_string

            class_attributes = []
            attribute_count.times { class_attributes << amf3_read_string } # Read class members

            traits =
                {
                    class_name: class_name,
                    members:    class_attributes,
                    dynamic:    dynamic
                }
            @cache_traits << traits
          end

          result = @class_mapper.create_object(traits[:class_name])
          @cache_objects << result

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

          @class_mapper.object_deserialize(result, properties)
        end

        result
      end

      private
      def amf3_read_date
        result = nil

        type = amf3_read_integer

        result = get_as_reference_object(type)

        if result.nil?
          seconds = read_double(@source).to_f / 1000
          result  = Time.at(seconds)
          @cache_objects << result
        end

        result
      end

      private
      def amf3_read_dictionary
        result = nil

        type = amf3_read_integer

        result = get_as_reference_object(type)

        if result.nil?
          result = {}
          @cache_objects << result
          length    = type >> 1
          weak_keys = read_int8(@source) # Ignore: Not supported in ruby

          0.upto(length - 1) do |i|
            result[amf3_deserialize] = amf3_deserialize
          end

        end

        result
      end

    end #Deserializer
  end #Pure
end