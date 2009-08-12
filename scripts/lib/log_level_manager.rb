# === Synopsis:
#   RightScale Log Level Manager (rs_log_level)
#   (c) 2009 RightScale
#
#   Log level manager allows setting and retrieving the RightLink agent
#   log level.
#
# === Examples:
#   Retrieve log level:
#     rs_log_level
#
#   Set log level to debug:
#     rs_log_level --log-level debug
#     rs_log_level -l debug
#
#  === Usage
#    rs_set_log_level [--log-level, -l debug|info|warn|error|fatal]
#
#    Options:
#      --log-level, -l LVL  Set log level of RightLink agent
#      --verbose, -v        Display debug information
#      --help:              Display help
#      --version:           Display version information
#
#    No options prints the current RightLink agent log level
#
$:.push(File.dirname(__FILE__))

require 'optparse'
require 'rdoc/ri/ri_paths' # For backwards compat with ruby 1.8.5
require 'rdoc/usage'
require 'rdoc_patch'
require 'command_client'
require File.join(File.dirname(__FILE__), '..', '..', 'actors', 'lib', 'agent_manager')

module RightScale

  class LogLevelManager

    VERSION = [0, 1]

    # Set log level
    #
    # === Parameters
    # options<Hash>:: Hash of options as defined in +parse_args+
    #
    # === Return
    # true:: Always return true
    def run(options)
      level = options[:level]
      cmd = { :name => (level ? 'set_log_level' : 'get_log_level') }
      cmd[:level] = level.to_sym if level
      client = CommandClient.new
      begin
        client.send_command(cmd, options[:verbose]) do |lvl|
          current = case lvl
            when Logger::DEBUG then 'DEBUG'
            when Logger::INFO  then 'INFO'
            when Logger::WARN  then 'WARN'
            when Logger::ERROR then 'ERROR'
            when Logger::FATAL then 'FATAL'
            else 'UNKNOWN'
          end
          puts "Agent log level: #{current}"
        end
      rescue Exception => e
        fail(e.message)
      end
      true
    end

    # Create options hash from command line arguments
    #
    # === Return
    # options<Hash>:: Hash of options as defined by the command line
    def parse_args
      options = { :verbose => false }

      opts = OptionParser.new do |opts|

        opts.on('-l', '--log-level LEVEL') do |l|
          fail("Invalid log level '#{l}'") unless AgentManager::LEVELS.include?(l.to_sym)
          options[:level] = l
        end

        opts.on('-v', '--verbose') do
          options[:verbose] = true
        end

      end

      opts.on_tail('--version') do
        puts version
        exit
      end

      opts.on_tail('--help') do
         RDoc::usage_from_file(__FILE__)
         exit
      end

      opts.parse!(ARGV)
      options
    end

protected

    # Print error on console and exit abnormally
    #
    # === Parameter
    # msg<String>:: Error message, default to nil (no message printed)
    # print_usage<Boolean>:: Whether script usage should be printed, default to false
    #
    # === Return
    # R.I.P. does not return
    def fail(msg=nil, print_usage=false)
      puts "** #{msg}" if msg
      RDoc::usage_from_file(__FILE__) if print_usage
      exit(1)
    end

    # Version information
    #
    # === Return
    # ver<String>:: Version information
    def version
      ver = "run_log_level #{VERSION.join('.')} - RightLink's dynamic log level manager (c) 2009 RightScale"
    end

  end
end