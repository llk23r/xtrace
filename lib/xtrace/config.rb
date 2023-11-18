module XTrace
  class Configuration
    # Define all configurable attributes here
    attr_accessor :enabled, :output_directory, :valid_auth_tokens, :exclude_from_trace

    def initialize
      # Set default values
      @enabled = true
      @output_directory = 'traces'
      @valid_auth_tokens = ENV['XTRACE_VALID_TOKENS']&.split(',') || []
      @exclude_from_trace = []
    end
  end

  # Method to configure the gem in an initializer
  def self.configure
    yield(configuration)
  end

  # Singleton instance of the Configuration class
  def self.configuration
    @configuration ||= Configuration.new
  end
end
