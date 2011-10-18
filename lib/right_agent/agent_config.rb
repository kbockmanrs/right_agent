#
# Copyright (c) 2009-2011 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module RightScale

  # Helper methods for accessing RightAgent files, directories, and processes.
  # Values returned are driven by root_dir, cfg_dir, and pid_dir, which may be set
  # but have defaults, and secondarily by the contents of the associated agent
  # configuration file generated by the 'rad' tool.
  #
  # The root_dir may be specified to be a list of root directories to be searched
  # when looking for agent files. It defaults to the current working directory.
  # A root directory is assumed to contain some or all of the following directories:
  #   init    - initialization code
  #   actors  - actor code
  #   certs   - security certificates and keys
  #   lib     - additional agent code
  #   scripts - tools code
  #
  # The init directory contains the following initialization code:
  #   config.yml - static configuration settings for the agent
  #   init.rb    - code that registers the agent's actors and performs any other
  #                agent specific initialization such as initializing its
  #                secure serializer and its command protocol server
  #
  # The certs directory contains the x.509 public certificate and keys needed
  # to sign and encrypt all outgoing messages as well as to check the signature
  # and decrypt any incoming messages. This directory should contain at least:
  #   <agent name>.key  - agent's' private key
  #   <agent name>.cert - agent's' public certificate
  #   mapper.cert       - mapper's' public certificate
  #
  # The scripts directory at a minimum contains the following:
  #   install.sh - script for installing standard and agent specific tools in /usr/bin
  #
  # The cfg_dir is the path to the directory containing a directory for each agent
  # configured on the local machine (e.g., core, core_2, core_3). Each agent directory
  # in turn contains a config.yml file generated to contain that agent's current
  # configuration. The cfg_dir defaults to the platform specific cfg_dir.
  #
  # The pid_dir is the path to the directory where agent process id files are stored.
  # These files are typically named <agent identity>.pid. The pid_dir defaults to the
  # current to the platform specific pid_dir.
  module AgentConfig

    # Current agent protocol version
    PROTOCOL_VERSION = 19

    # Current agent protocol version
    #
    # === Return
    # (Integer):: Protocol version
    def self.protocol_version
      PROTOCOL_VERSION
    end

    # Initialize path to root directory of agent
    #
    # === Parameters
    # dir(String|Array):: Directory path or ordered list of directory paths to be searched
    #
    # === Return
    # (String):: Ordered list of directory paths to be searched
    def self.root_dir=(dir)
      @root_dirs = array(dir)
    end

    # Initialize path to directory containing generated agent configuration files
    #
    # === Parameters
    # dir(String):: Directory path
    #
    # === Return
    # (String):: Directory path
    def self.cfg_dir=(dir)
      @cfg_dir = dir
    end

    # Initialize path to directory containing agent process id files
    #
    # === Parameters
    # dir(String):: Directory path
    #
    # === Return
    # (String):: Directory path
    def self.pid_dir=(dir)
      @pid_dir = dir
    end

    # Root directory path(s)
    #
    # === Return
    # (String|Array):: Individual directory path if only one, otherwise array of paths
    def self.root_dir
      (d = root_dirs).size > 1 ? d : d.first
    end

    # Path to agent init.rb file containing code that registers the agent's actors
    # and performs any other agent specific initialization such as initializing its
    # secure serializer and its command protocol server
    #
    # === Return
    # (String|nil):: File path name, or nil if file does not exist
    def self.init_file
      first_file(:init_dir, "init.rb")
    end

    # Path to agent config.yml file containing static configuration settings
    #
    # === Return
    # (String|nil):: File path name, or nil if file does not exist
    def self.init_cfg_file
      first_file(:init_dir, "config.yml")
    end

    # Ordered list of directory path names for searching for actors:
    #  - actors directory in each configured root directory
    #  - other directories produced by other_actors_dirs method, e.g., in other associated gems
    #  - actors directory in RightAgent gem
    #
    # === Return
    # actors_dirs(Array):: List of directory path names
    def self.actors_dirs
      actors_dirs = all_dirs(:actors_dir)
      actors_dirs += other_actors_dirs if self.respond_to?(:other_actors_dirs)
      actors_dirs << File.normalize_path(File.join(File.dirname(__FILE__), 'actors'))
      actors_dirs
    end

    # Path to directory containing certificates
    #
    # === Parameters
    # root_dir(String|nil):: Specific root dir to use (must be in root_dirs),
    #   if nil use first dir in root_dirs
    #
    # === Return
    # (String|nil):: Path to certs directory, or nil if cannot determine root_dir
    def self.certs_dir(root_dir = nil)
      if root_dir
        root_dir = nil unless @root_dirs && @root_dirs.include?(root_dir)
      else
        root_dir = @root_dirs.first if @root_dirs
      end
      File.normalize_path(File.join(root_dir, "certs")) if root_dir
    end

    # Path to security file containing X.509 data
    #
    # === Parameters
    # name(String):: Security file name
    #
    # === Return
    # file(String|nil):: File path name, or nil if file does not exist
    def self.certs_file(name)
      first_file(:certs_dir, name)
    end

    # All security files matching pattern
    #
    # === Parameters
    # pattern(String):: Pattern for security files of interest, e.g., '*.cert'
    #
    # === Return
    # files(Array):: Path name of files found
    def self.certs_files(pattern)
      files = []
      names = []
      all_dirs(:certs_dir).each do |d|
        certs = Dir.glob(File.join(d, pattern)).each do |f|
          unless names.include?(b = File.basename(f))
            files << f
            names << b
          end
        end
      end
      files
    end

    # Path to first agent lib directory
    #
    # === Return
    # dir(String):: Directory path name
    def self.lib_dir
      all_dirs(:lib_dir2).first
    end

    # Path to first agent scripts directory
    #
    # === Return
    # dir(String):: Directory path name
    def self.scripts_dir
      all_dirs(:scripts_dir2).first
    end

    # Path to directory containing a directory for each agent configured on the local machine
    #
    # === Return
    # (String):: Directory path name
    def self.cfg_dir
      @cfg_dir ||= Platform.filesystem.cfg_dir
    end

    # Path to generated agent configuration file
    #
    # === Parameters
    # agent_name(String):: Agent name
    # exists(Boolean):: Whether to return nil if does not exist
    #
    # === Return
    # (String):: Configuration file path name, or nil if file does not exist
    def self.cfg_file(agent_name, exists = false)
      file = File.normalize_path(File.join(cfg_dir, agent_name, "config.yml"))
      file = nil unless !exists || File.exist?(file)
      file
    end

    # Configuration file path names for all agents configured locally
    #
    # === Return
    # (Array):: Agent configuration file path names
    def self.cfg_files
      Dir.glob(File.join(cfg_dir, "**", "*.yml"))
    end

    # Configured agents i.e. agents that have a configuration file
    #
    # === Return
    # (Array):: Name of configured agents
    def self.cfg_agents
      cfg_files.map { |c| File.basename(File.dirname(c)) }
    end

    # Agent name associated with given agent identity
    #
    # === Parameters
    # agent_id(String):: Serialized agent identity
    #
    # === Return
    # (String|nil):: Agent name, or nil if agent not found
    def self.agent_name(agent_id)
      cfg_agents.each do |a|
        if (options = agent_options(a)) && options[:identity] == agent_id
          return a
        end
      end
      nil
    end

    # Get options from agent's configuration file
    #
    # === Parameters
    # agent_name(String):: Agent name
    #
    # === Return
    # (Hash|nil):: Agent options with key names symbolized,
    #   or nil if file not accessible or empty
    def self.load_cfg(agent_name)
      if (file = cfg_file(agent_name, exists = true)) && File.readable?(file) && (cfg = YAML.load(IO.read(file)))
        SerializationHelper.symbolize_keys(cfg)
      end
    end

    # Write agent's configuration to file
    #
    # === Parameters
    # agent_name(String):: Agent name
    # cfg(Hash):: Configuration options
    #
    # === Return
    # file(String):: Configuration file path name
    def self.store_cfg(agent_name, cfg)
      file = cfg_file(agent_name)
      FileUtils.mkdir_p(File.dirname(file))
      File.delete(file) if File.exists?(file)
      File.open(file, 'w') do |fd|
        fd.puts "# Created at #{Time.now}"
        fd.write(YAML.dump(cfg))
      end
      file
    end

    # Path to directory containing agent process id files
    #
    # === Return
    # (String):: Directory path name
    def self.pid_dir
      @pid_dir ||= Platform.filesystem.pid_dir
    end

    # Retrieve agent process id file
    #
    # === Parameters
    # agent_name(String):: Agent name
    #
    # === Return
    # (PidFile|nil):: Process id file, or nil if there is no configuration file for agent
    def self.pid_file(agent_name)
      if options = load_cfg(agent_name)
        PidFile.new(options[:identity], options[:pid_dir])
      end
    end

    # Agent options from generated agent configuration file
    # and agent process id file if they exist
    # Reset root_dir and pid_dir to one found in agent configuration file
    #
    # === Parameters
    # agent_name(String):: Agent name
    #
    # === Return
    # options(Hash):: Agent options including
    #   :identity(String):: Serialized agent identity
    #   :log_path(String):: Path to directory for agent log file
    #   :pid(Integer):: Agent process pid if available
    #   :listen_port(Integer):: Agent command listen port if available
    #   :cookie(String):: Agent command cookie if available
    def self.agent_options(agent_name)
      if options = load_cfg(agent_name)
        @root_dirs = array(options[:root_dir])
        @pid_dir = options[:pid_dir]
        options[:log_path] = options[:log_dir] || Platform.filesystem.log_dir
        pid_file = PidFile.new(options[:identity])
        options.merge!(pid_file.read_pid) if pid_file.exists?
      end
      options || {}
    end

    # Agents that are currently running
    #
    # === Parameters
    # (Regexp):: Pattern that agent name must match to be included
    #
    # === Return
    # (Array):: Name of running agents
    def self.running_agents(pattern = //)
      AgentConfig.cfg_agents.select do |agent_name|
        agent_name =~ pattern &&
        (pid_file = AgentConfig.pid_file(agent_name)) &&
        (pid = pid_file.read_pid[:pid]) &&
        (Process.getpgid(pid) rescue -1) != -1
      end.sort
    end

    protected

    # Convert value to array if not an array, unless nil
    def self.array(value)
      (value.nil? || value.is_a?(Array)) ? value : [value]
    end

    # Ordered list of root directories
    def self.root_dirs
      @root_dirs || [Dir.pwd]
    end

    # Path to agent directory containing initialization files
    def self.init_dir(root_dir)
      File.normalize_path(File.join(root_dir, "init"))
    end

    # Path to directory containing actor source files
    def self.actors_dir(root_dir)
      File.normalize_path(File.join(root_dir, "actors"))
    end

    # Path to agent directory containing code
    def self.lib_dir2(root_dir)
      File.normalize_path(File.join(root_dir, "lib"))
    end

    # Path to agent directory containing scripts
    def self.scripts_dir2(root_dir)
      File.normalize_path(File.join(root_dir, "scripts"))
    end

    # All existing directories of given type
    def self.all_dirs(type)
      dirs = []
      root_dirs.each do |d|
        c = self.__send__(type, d)
        dirs << c if File.directory?(c)
      end
      dirs
    end

    # Path name of first file found of given type and name, or nil if none found
    def self.first_file(type, name)
      file = nil
      root_dirs.each do |d|
        if File.exist?(f = File.join(self.__send__(type, d), name))
          file = f
          break
        end
      end
      file
    end

  end # AgentConfig

end # RightScale
