module AMF
  # Hash-like object that can store a type string. Used to preserve type information
  # for unmapped objects after deserialization.
  class HashWithType < Hash

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