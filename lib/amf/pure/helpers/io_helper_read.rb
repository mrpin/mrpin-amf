require 'amf/pure/helpers/io_helper_base'

module AMF
  module Pure
    module IOHelperRead #:nodoc:

      include IOHelperBase

      #
      # Methods
      #

      public
      def read_int8(source)
        raise AMFErrorIncomplete.new if source.eof?

        source.read(1).unpack('c').first
      end

      public
      def read_word8(source)
        raise AMFErrorIncomplete.new if source.eof?

        source.read(1).unpack('C').first
      end

      public
      def read_double(source)
        bytes_to_read = 8

        raise AMFErrorIncomplete.new if bytes_to_read > (source.size - source.pos)

        source.read(bytes_to_read).unpack('G').first
      end

      public
      def read_word16_network(source)
        bytes_to_read = 2

        raise AMFErrorIncomplete.new if bytes_to_read > (source.size - source.pos)

        source.read(2).unpack('n').first
      end

      public
      def read_int16_network(source)
        bytes_to_read = 2

        raise AMFErrorIncomplete.new if bytes_to_read > (source.size - source.pos)

        result = source.read(bytes_to_read)
        result.reverse! if byte_order_little? # swap bytes as native=little (and we want network)
        result.unpack('s').first
      end

      public
      def read_word32_network(source)
        bytes_to_read = 4

        raise AMFErrorIncomplete.new if bytes_to_read > (source.size - source.pos)

        source.read(bytes_to_read).unpack('N').first
      end

    end
  end
end