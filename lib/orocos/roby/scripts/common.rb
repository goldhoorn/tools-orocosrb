require 'optparse'
require 'orocos'
require 'orocos/roby'
require 'orocos/roby/app'

module Orocos
    module RobyPlugin
        module Scripts
            class << self
                attr_accessor :debug
                attr_accessor :output_file
                attr_accessor :output_type
                attr_accessor :robot_type
                attr_accessor :robot_name
            end
            @debug = false
            @output_type = 'txt'

            def self.tic
                @tic = Time.now
            end
            def self.toc(string = nil)
                if string
                    STDERR.puts string % [Time.now - @tic]
                else STDERR.puts yield(Time.now - @tic)
                end
            end
            def self.toc_tic(string = nil, &block)
                toc(string, &block)
                tic
            end

            def self.resolve_service_name(service)
                engine = Roby.app.orocos_engine
                if !engine.robot.has_device?(service) && !engine.has_definition?(service)
                    if engine.model.has_composition?(service)
                        service = engine.model.composition_model(service)
                    elsif model = Roby.app.orocos_tasks[service]
                        service = model
                    end
                end
                service
            end

            def self.common_options(opt, with_output = false)
                opt.on('--debug', "turn debugging output on") do
                    Scripts.debug = true
                end
                if with_output
                    opt.on('-o TYPE[:file]', '--output=TYPE[:file]', String, 'in what format to output the result (can be: txt, dot, png or svg), defaults to txt') do |output_arg|
                        output_type, output_file = output_arg.split(':')
                        Scripts.output_file = output_file
                        Scripts.output_type = output_type.downcase
                    end
                end
                Roby::Application.common_optparse_setup(opt)
            end

            def self.setup
            end

            def self.run
                error = Roby.display_exception do
                    tic = Time.now
                    Roby.app.filter_backtraces = !debug
                    Roby.app.using_plugins 'orocos'
                    if debug
                        RobyPlugin.logger = ::Logger.new(STDOUT)
                        RobyPlugin.logger.formatter = Roby.logger.formatter
                        RobyPlugin.logger.level = ::Logger::DEBUG
                        Engine.logger = ::Logger.new(STDOUT)
                        Engine.logger.formatter = Roby.logger.formatter
                        Engine.logger.level = ::Logger::DEBUG
                        SystemModel.logger = ::Logger.new(STDOUT)
                        SystemModel.logger.formatter = Roby.logger.formatter
                        SystemModel.logger.level = ::Logger::DEBUG
                    end

                    Roby.app.setup
                    toc = Time.now
                    STDERR.puts "loaded Roby application in %.3f seconds" % [toc - tic]

                    yield
                end

                if error
                    exit(1)
                end
            ensure Roby.app.stop_process_servers
            end
        end
    end
end

