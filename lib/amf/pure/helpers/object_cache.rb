module AMF
  module Pure
    class ObjectCache < Hash #:nodoc:
      def initialize
        @cache_index    = 0
        @obj_references = []
      end

      def [](obj)
        super(obj.object_id)
      end

      def add_obj(obj)
        @obj_references << obj
        self[obj.object_id] = @cache_index
        @cache_index        += 1
      end
    end
  end
end