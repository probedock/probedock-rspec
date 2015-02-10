require 'fileutils'
require 'rake/tasklib'

module ProbeDockRSpec

  class Tasks < ::Rake::TaskLib

    def initialize

      namespace :spec do

        namespace 'probe-dock' do

          desc "Generate a test run UID to group test results in Probe Dock (stored in an environment variable)"
          task :uid do
            trace do
              uid = uid_manager.generate_uid_to_env
              puts Paint["Probe Dock - Generated UID for test run: #{uid}", :cyan]
            end
          end

          namespace :uid do

            desc "Generate a test run UID to group test results in Probe Dock (stored in a file)"
            task :file do
              trace do
                uid = uid_manager.generate_uid_to_file
                puts Paint["Probe Dock - Generated UID for test run: #{uid}", :cyan]
              end
            end

            desc "Clean the test run UID (file and environment variable)"
            task :clean do
              trace do
                uid_manager.clean_uid
                puts Paint["Probe Dock - Cleaned test run UID", :cyan]
              end
            end
          end
        end
      end
    end

    private

    def trace &block
      if Rake.application.options.trace
        block.call
      else
        begin
          block.call
        rescue UID::Error => e
          warn Paint["Probe Dock - #{e.message}", :red]
        end
      end
    end

    def uid_manager
      UID.new ProbeDockRSpec.config.client_options
    end
  end
end
