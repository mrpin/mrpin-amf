module AMF

  # Container for all mapped classes
  class MappingSet

    #
    # Methods
    #

    # Creates a mapping set object and populates the default mappings
    public
    def initialize
      @mappings_remote = {}
      @mappings_local  = {}
    end

    # Map a given other-language class to a ruby class.
    #
    # Use fully qualified names for both.
    #
    # Example:
    #
    #   register_class_alias('Example::Date', 'com.example.Date')
    public
    def register_class_alias(class_local, class_remote)
      # Convert params to strings
      class_remote = class_remote.to_s
      class_local  = class_local.to_s

      @mappings_remote[class_remote] = class_local
      @mappings_local[class_local]   = class_remote
    end

    # Returns the ruby class name for the given other-language class name
    # returning nil if not found
    public
    def get_class_name_local(class_name) #:nodoc:
      @mappings_remote[class_name.to_s]
    end

    # Returns the other-language class name for the given ruby class name,
    # returning nil if not found
    public
    def get_class_name_remote(class_name) #:nodoc:
      @mappings_local[class_name.to_s]
    end
  end

end