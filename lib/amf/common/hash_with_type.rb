module AMF
  # Hash-like object that can store a type string. Used to preserve type information
  # for unmapped objects after deserialization.
  class HashWithType < Hash

    #
    # Properties
    #

    attr_reader :class_type

    #
    # Methods
    #

    def initialize(type)
      @class_type = type
    end
  end
end