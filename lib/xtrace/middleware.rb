# frozen_string_literal: true

require_relative "html_generator"
require "securerandom"
require "digest"

module XTrace
  class Middleware
    def initialize(app, config = XTrace.configuration)
      @app = app
      @config = config
      @rails_root = Rails.root.join("app").to_s
      @source_buffers = {} # Buffer for source file lines
      @cwd = Dir.pwd
    end

    def call(env)
      req = Rack::Request.new(env)
      puts "[Xtrace]: Loaded!"
      tracing_enabled?(req.params) ? perform_tracing(env) : @app.call(env)
    end

    private

      def perform_tracing(env)
        puts "[Xtrace] Initiating trace.."
        root_call = { child_calls: [], lines: [], events: [] }
        trace = setup_trace(root_call)
        trace.enable
        status, headers, body = @app.call(env)
        trace.disable
        finalize_trace(root_call, status, headers, body)
      end

      def setup_trace(root_call)
        call_stack = [root_call]
        scope_stack = []
        TracePoint.new(:line, :call, :return, :class, :end) do |tp|
          next unless tp.path.start_with?(@cwd)
          next if tp.method_id.nil?
          next if exclude_trace_path?(tp.path)
          handle_trace_event(call_stack, scope_stack, tp)
        end
      end

      def handle_trace_event(call_stack, scope_stack, tp)
        current_call = call_stack.last
        return if current_call.nil?
        current_scope = scope_stack.last || { start_line: 1, end_line: nil }
        start_time = Time.now.to_f
        initial_gc_stats = GC.stat

        event = build_event(tp, current_scope, start_time, initial_gc_stats)

        case tp.event
        when :line, :class, :module
          current_call[:events] << event
        when :call
          new_call, new_scope = build_new_call_and_scope(event, tp)
          current_call[:events] << { type: :call, call: new_call }
          call_stack.push(new_call)
          scope_stack.push(new_scope)
        when :return, :end
          finalize_current_call_and_scope(current_call, current_scope, event, tp)
          call_stack.pop unless call_stack.empty?
          scope_stack.pop unless scope_stack.empty?
        end
      end

      def build_event(tp, current_scope, start_time, initial_gc_stats)
        line_content, statement_content = get_line_and_statement_content(tp.path, tp.lineno)
        end_time = Time.now.to_f
        time_taken = end_time - start_time

        final_gc_stats = GC.stat
        relevant_gc_metric = final_gc_stats[:heap_live_slots]
        heap_size_diff = final_gc_stats[:heap_live_slots] - initial_gc_stats[:heap_live_slots]

        {
          type: tp.event,
          line: tp.lineno,
          line_content: line_content,
          statement_content: statement_content,
          method: tp.method_id,
          file: tp.path,
          variables: capture_variables(tp.binding),
          thread_id: Thread.current.object_id,
          instance_id: tp.self.object_id,
          visibility: tp.defined_class.private_method_defined?(tp.method_id) ? "private" : "public",
          class_or_module: tp.self.is_a?(Class) ? tp.self.name : tp.self.class.name,
          scope: current_scope,
          return_value: (tp.return_value if tp.event == :return),
          time_taken: time_taken,
          heap_size_diff: heap_size_diff,
          gc_metric: relevant_gc_metric
        }
      end

      def get_line_and_statement_content(file_path, lineno)
        load_source_buffer(file_path) unless @source_buffers[file_path]
        line_content = @source_buffers[file_path][lineno - 1].strip

        # Find the complete statement that might span multiple lines
        statement_content = line_content
        open_brackets = line_content.count("{[(<") - line_content.count("}])>")
        index = lineno
        while open_brackets.positive?
          index += 1
          next_line_content = @source_buffers[file_path][index - 1]
          statement_content += next_line_content.strip
          open_brackets += next_line_content.count("{[(<") - next_line_content.count("}])>")
        end

        [line_content, statement_content]
      end

      def load_source_buffer(file_path)
        @source_buffers[file_path] = File.readlines(file_path).map(&:rstrip)
      end

      def build_new_call_and_scope(event, tp)
        new_call = {
          method_name: tp.method_id,
          file: tp.path,
          start_line: tp.lineno,
          end_line: nil,
          visibility: event[:visibility],
          class_or_module: event[:class_or_module],
          thread_id: event[:thread_id],
          instance_id: event[:instance_id],
          arguments: capture_variables(tp.binding),
          child_calls: [],
          lines: [],
          events: [event]
        }
        new_scope = { start_line: tp.lineno, end_line: nil }
        [new_call, new_scope]
      end

      def finalize_current_call_and_scope(current_call, current_scope, event, tp)
        current_call[:end_line] = tp.lineno
        current_scope[:end_line] = tp.lineno if current_scope
        current_call[:events] << event
      end

      def finalize_trace(root_call, status, headers, body)
        trace_id = SecureRandom.uuid
        root_call[:trace_id] = trace_id
        output_directory = @config.output_directory
        Dir.mkdir(output_directory) unless Dir.exist?(output_directory)
        output_json_file_path = "#{output_directory}/#{trace_id}.json"
        File.write(output_json_file_path, root_call.to_json)
        puts "[XTrace]: Generated trace json at: #{output_json_file_path}"
        html_output = XTrace::HTMLGenerator.generate(root_call.to_json)
        output_html_file_path = output_json_file_path.sub("json", "html")
        File.write(output_html_file_path, html_output)
        puts "[XTrace]: Generated trace html at: #{output_html_file_path}"
        [status, headers.merge("X-Trace-Id" => trace_id, "Content-Type" => "text/html"), [html_output.to_s]]
      end

      def tracing_enabled?(params)
        @config.enabled && params["trace"] == "true" && @config.valid_auth_tokens.include?(params["auth"])
      end

      def capture_variables(binding)
        # Only capture variables that are already initialized
        binding.local_variables.each_with_object({}) do |var, h|
          value = binding.local_variable_get(var)
          # Recursively convert Rails objects to a hash
          h[var] = serialize_rails_object(value)
        end
      end

      def serialize_rails_object(object)
        case object
        when ActiveRecord::Base
          # Convert the object's attributes to a hash and serialize any ActiveRecord associations
          object.attributes.each_with_object({}) do |(key, value), hash|
            hash[key] = serialize_rails_object(value)
          end
        when Enumerable
          # For Enumerable objects, serialize each element
          object.map { |element| serialize_rails_object(element) }
        else
          # If it's not a Rails object or Enumerable, return the value as is
          object
        end
      end

      def exclude_trace_path?(path)
        @config.exclude_from_trace.any? { |exclude_path| path.start_with?("#{@rails_root}/#{exclude_path}") }
      end
  end
end
