require 'paint'
require 'fileutils'
require 'rspec/core/formatters/base_formatter'

module ProbeDockRSpec

  class Formatter

    RSpec::Core::Formatters.register self, :start, :stop, :close,
      :example_group_started, :example_started, :example_passed, :example_failed, :example_group_finished

    def initialize output

      config = ProbeDockRSpec.config
      @client = Client.new config.server, config.client_options
      @test_run = TestRun.new config.project

      @groups = []
    end

    def start notification
      # TODO: measure milliseconds
      @start_time = Time.now
    end

    def example_group_started group_notification
      @groups << group_notification.group
    end

    def example_group_finished group_notification
      @groups.pop
    end

    def example_started example_notification
      @current_time = Time.now
    end

    def example_passed example_notification
      add_result example_notification, true
    end

    def example_failed example_notification
      add_result example_notification, false
    end

    def stop notification
      end_time = Time.now
      @test_run.end_time = end_time.to_i * 1000
      @test_run.duration = ((end_time - @start_time) * 1000).round
    end

    def close notification
      @client.process @test_run
    end

    private

    def add_result example_notification, successful

      options = {
        passed: successful,
        duration: ((Time.now - @current_time) * 1000).round
      }

      options[:message] = failure_message example_notification unless successful

      @test_run.add_result example_notification.example, @groups, options
    end

    def failure_message example_notification
      String.new.tap do |m|
        m << example_notification.description
        m << "\n"
        m << example_notification.message_lines.collect{ |l| "  #{l}" }.join("\n")
        m << "\n"
        m << example_notification.formatted_backtrace.collect{ |l| "  # #{l}" }.join("\n")
      end
    end

    def full_example_name example
      (@groups.collect{ |g| g.description.strip } << example.description.strip).join ' '
    end
  end
end
