#
# Copyright (c) 2010 RightScale Inc
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

  # Base class to dynamically generated Powershell Chef providers
  class PowershellProviderBase < Chef::Provider

    # Initialize Powershell host, should be called before :run and :terminate
    #
    # === Return
    # true:: Always return true
    def self.init
      @@ps_instance = PowershellHost.new(:chef_node => @node)
      true
    end

    # Run powershell script in associated Powershell instance
    #
    # === Parameters
    # script(String):: Fully qualified path to Powershell script
    #
    # === Return
    # true:: Always return true
    def self.run_script(script)
      if @@ps_instance.active
        @@ps_instance.run(script)
      else
        RightLinkLog.error("Powershell provider #{self.class.name} could not run Powershell script #{script} because the Powershell host is not active")
      end
      true
    end

    # Terminate Powershell process if it was started
    #
    # === Return
    # true:: Always return true
    def self.terminate
      @@ps_instance.terminate if defined?(@@ps_instance)
      true
    end

  end

end