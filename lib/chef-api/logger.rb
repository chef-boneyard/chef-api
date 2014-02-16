require 'logger'

module ChefAPI
  module Logger
    class << self
      # @private
      def included(base)
        base.send(:extend,  ClassMethods)
        base.send(:include, InstanceMethods)
      end

      #
      # Get the logger class for the given name. If a logger does not exist
      # for the given name, a new one is created.
      #
      # @param [String] name
      #   the name of the logger to find
      #
      # @return [DefaultLogger]
      #   the logger for the given name
      #
      def logger_for(name)
        loggers[name] ||= DefaultLogger.new(name, level)
      end

      #
      # The global log level.
      #
      # @return [Symbol]
      #
      def level
        @level ||= :warn
      end

      #
      # Set the global log level.
      #
      # @param [String, Symbol] level
      #   the log level
      #
      # @return [Symbol]
      #
      def level=(level)
        @level = level.to_s.downcase.to_sym

        loggers.each do |_, logger|
          logger.level = @level
        end

        @level
      end

      private

      def loggers
        @loggers ||= {}
      end
    end

    module ClassMethods
      #
      # Write a message to the logger for this class.
      #
      # @return [DefaultLogger]
      #
      def log
        @log ||= Logger.logger_for(name)
      end
    end

    module InstanceMethods
      #
      # Write a message to the logger for this instance's class.
      #
      # @return [DefaultLogger]
      #
      def log
        @log ||= Logger.logger_for(self.class.name)
      end
    end

    #
    # The default logger for everything logged through the Chef API.
    #
    class DefaultLogger < ::Logger
      class << self
        private

        #
        # @macro attr_questioner
        #
        #   @method $1?
        #     Determine if the current logger's level is +:$1+.
        #
        #     @return [Boolean]
        #       true if the current log level is +:$1+ or lower, false otherwise
        #
        def attr_questioner(name)
          class_eval <<-EOH, __FILE__, __LINE__ + 1
            def #{name}?
              level == ::Logger::Severity.const_get('#{name}'.upcase)
            end
          EOH
        end
      end

      attr_questioner :fatal
      attr_questioner :error
      attr_questioner :warn
      attr_questioner :info
      attr_questioner :debug

      #
      # Create a new logger with the given name. In debug mode, the +name+ is
      # used to identify the caller of the log message. In other modes, it is
      # ignored entirely.
      #
      # @param [String] name
      #   the name of the class calling the logger
      #
      def initialize(name, level)
        super($stdout)

        @formatter = formatter
        @progname  = name
        self.level = level
      end

      #
      # Set this logger's level to the given key.
      #
      # @example Set the log level to +info+
      #   logger.level = :info
      #
      # @param [String, Symbol] value
      #   the value to set for the logger
      #
      def level=(value)
        @level = ::Logger::Severity.const_get(value.to_s.upcase)
      end

      private

      def formatter
        Proc.new do |severity, timestamp, progname, message|
          if debug?
            "[#{progname}] #{message}\n"
          else
            message + "\n"
          end
        end
      end
    end

    class NullLogger < DefaultLogger
      def initialize(*args); end
      def add(*args, &block); end
    end
  end
end
