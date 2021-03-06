module Orocos
    module RubyTasks

    # Representation and management of a set of ruby tasks
    #
    # This provides a {Orocos::Process}-compatible API to ruby tasks. It allows
    # to define tasks in an oroGen deployment model and "spawn" them all at
    # once, as well as dispose of them all at once.
    class Process < ProcessBase
        # The Ruby process server that spawned this process
        #
        # If non-nil, the object's #dead_deployment will be called when self is
        # stopped
        #
        # @return [#dead_deployment,nil]
        attr_reader :ruby_process_server

        # The set of deployed tasks
        #
        # @return [{String=>TaskContext}] mapping from the deployed task name as
        #   defined in {model} to the actual ruby task object
        attr_reader :deployed_tasks

        # The host on which this process' tasks run
        #
        # This is always 'localhost' as ruby tasks are instanciated inside the
        # ruby process
        #
        # @return [String]
        def host_id; 'localhost' end

        # Whether the tasks in this process are running on the same machine than
        # the ruby process
        #
        # This is always true as ruby tasks are instanciated inside the ruby
        # process
        #
        # @return [Boolean]
        def on_localhost?; true end

        # The PID of the process in which the tasks run
        #
        # This is always Process.pid as ruby tasks are instanciated inside the ruby
        # process
        #
        # @return [Integer]
        def pid; Process.pid end

        # Creates a new ruby task process
        #
        # @param [nil,#dead_deployment] ruby_process_server the process manager
        #   which creates this process. If non-nil, its #dead_deployment method
        #   will be called when this process stops
        # @param [String] name the process name
        # @param [OroGen::Spec::Deployment] model the deployment model
        def initialize(ruby_process_server, name, model)
            @ruby_process_server = ruby_process_server
            @deployed_tasks = Hash.new
            super(name, model)
        end

        # Deploys the tasks defined in {model} as ruby tasks
        #
        # @return [void]
        def spawn(options = Hash.new)
            model.task_activities.each do |deployed_task|
                deployed_tasks[deployed_task.name] = TaskContext.
                    from_orogen_model(get_mapped_name(deployed_task.name), deployed_task.task_model)
            end
            @alive = true
        end

        # Waits for the tasks to be ready
        #
        # This is a no-op for ruby tasks as they are ready as soon as they are
        # created
        def wait_running(blocking = false)
            true
        end

        def task(task_name)
            if t = deployed_tasks[task_name]
                t
            else raise ArgumentError, "#{self} has no task called #{task_name}"
            end
        end

        def kill(wait = true, status = ProcessManager::Status.new(:exit_code => 0))
            deployed_tasks.each_value do |task|
                task.dispose
            end
            dead!(status)
        end

        def dead!(status = ProcessManager::Status.new(:exit_code => 0))
            @alive = false
            if ruby_process_server
                ruby_process_server.dead_deployment(name, status)
            end
        end

        def join
            raise NotImplementedError, "RemoteProcess#join is not implemented"
        end

        # True if the process is running. This is an alias for running?
        def alive?; @alive end
        # True if the process is running. This is an alias for alive?
        def running?; @alive end
    end
    end
end

