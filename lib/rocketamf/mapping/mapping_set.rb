module RocketAMF

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
      map_defaults
    end

    # Adds required mapping configs, calling map for the required base mappings.
    # Designed to allow extenders to take advantage of required default mappings.
    public
    def map_defaults
      map as: 'flex.messaging.messages.AbstractMessage', ruby: 'RocketAMF::Types::AbstractMessage'
      map as: 'flex.messaging.messages.RemotingMessage', ruby: 'RocketAMF::Types::RemotingMessage'
      map as: 'flex.messaging.messages.AsyncMessage', ruby: 'RocketAMF::Types::AsyncMessage'
      map as: 'DSA', ruby: 'RocketAMF::Types::AsyncMessageExt'
      map as: 'flex.messaging.messages.CommandMessage', ruby: 'RocketAMF::Types::CommandMessage'
      map as: 'DSC', ruby: 'RocketAMF::Types::CommandMessageExt'
      map as: 'flex.messaging.messages.AcknowledgeMessage', ruby: 'RocketAMF::Types::AcknowledgeMessage'
      map as: 'DSK', ruby: 'RocketAMF::Types::AcknowledgeMessageExt'
      map as: 'flex.messaging.messages.ErrorMessage', ruby: 'RocketAMF::Types::ErrorMessage'
      self
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