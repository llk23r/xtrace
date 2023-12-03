# frozen_string_literal: true

require 'erb'
require 'json'

module XTrace
  class HTMLGenerator
    def self.generate(trace_data)
      trace_id = JSON.parse(trace_data)["trace_id"]
      current_directory = File.dirname(__FILE__)
      template_path = File.join(current_directory, 'templates', 'trace_template.html.erb')
      template = File.read(template_path)
      x = ERB.new(template).result_with_hash(trace_id: trace_id, current_directory: current_directory, trace_data: trace_data)
      puts x
      x
    end
  end
end
