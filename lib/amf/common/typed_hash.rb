module AMF
  module Types #:nodoc:

    # Hash-like object that can store a type string. Used to preserve type information
    # for unmapped objects after deserialization.
    class TypedHash < Hash

      #
      # Properties
      #

      attr_reader :type

      #
      # Methods
      #

      def initialize(type)
        @type = type
      end
    end
  end
end