require 'rocketamf/pure/helpers/io_helper_base'

module RocketAMF
  module Pure
    module IOHelperWrite #:nodoc:

      include IOHelperBase

      def pack_integer(integer)
        integer = integer & 0x1fffffff
        if integer < 0x80
          [integer].pack('c')
        elsif integer < 0x4000
          [integer >> 7 & 0x7f | 0x80].pack('c')+
              [integer & 0x7f].pack('c')
        elsif integer < 0x200000
          [integer >> 14 & 0x7f | 0x80].pack('c') +
              [integer >> 7 & 0x7f | 0x80].pack('c') +
              [integer & 0x7f].pack('c')
        else
          [integer >> 22 & 0x7f | 0x80].pack('c')+
              [integer >> 15 & 0x7f | 0x80].pack('c')+
              [integer >> 8 & 0x7f | 0x80].pack('c')+
              [integer & 0xff].pack('c')
        end
      end

      def pack_double(double)
        [double].pack('G')
      end

      def pack_int8(val)
        [val].pack('c')
      end

      def pack_int16_network(val)
        [val].pack('n')
      end

      def pack_word32_network(val)
        result = [val].pack('L')
        result.reverse! if byte_order_little? # swap bytes as native=little (and we want network)
        result
      end

    end
  end
end