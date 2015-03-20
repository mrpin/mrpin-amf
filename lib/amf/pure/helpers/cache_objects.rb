module AMF
  module Pure
    class CacheObjects < Hash #:nodoc:
      def initialize
        @cache_index    = 0
      end

      def [](obj)
        super(obj.object_id)
      end

      def add_object(value)
        self[value.object_id] = @cache_index
        @cache_index        += 1
      end
    end
  end
end