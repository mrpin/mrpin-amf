module AMF
  module Pure
    class CacheStrings < Hash #:nodoc:
      def initialize
        @cache_index = 0
      end

      def add_string(value)
        self[value]    = @cache_index
        @cache_index += 1
      end
    end
  end
end