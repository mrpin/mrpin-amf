module RocketAMF
  module Pure
    module IOHelperBase

      def byte_order
        if [0x12345678].pack('L') == "\x12\x34\x56\x78"
          :BigEndian
        else
          :LittleEndian
        end
      end

      def byte_order_little?
        byte_order == :LittleEndian
      end

    end
  end
end