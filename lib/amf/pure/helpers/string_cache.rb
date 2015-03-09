module AMF
  module Pure
    class StringCache < Hash #:nodoc:
      def initialize
        @cache_index = 0
      end

      def add_obj(str)
        self[str]    = @cache_index
        @cache_index += 1
      end
    end
  end
end