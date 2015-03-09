module AMF

  # Container for all mapped classes
  class MappingSet

    #
    # Methods
    #

    # Creates a mapping set object and populates the default mappings
    public
    def initialize
      @as_mappings   = {}
      @ruby_mappings = {}
    end

    # Map a given AS class to a ruby class.
    #
    # Use fully qualified names for both.
    #
    # Example:
    #
    #   m.map as: 'com.example.Date', ruby: 'Example::Date'
    public
    def map(params)
      [:as, :ruby].each { |k| params[k] = params[k].to_s } # Convert params to strings
      @as_mappings[params[:as]]     = params[:ruby]
      @ruby_mappings[params[:ruby]] = params[:as]
    end

    # Returns the AS class name for the given ruby class name,
    # returning nil if not found
    public
    def get_as_class_name(class_name) #:nodoc:
      @ruby_mappings[class_name.to_s]
    end

    # Returns the ruby class name for the given AS class name
    # returning nil if not found
    public
    def get_ruby_class_name(class_name) #:nodoc:
      @as_mappings[class_name.to_s]
    end
  end

end