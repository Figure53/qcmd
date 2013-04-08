require 'dnssd'

module Qcmd
  # Browse the LAN and find open and running QLab instances.
  class Network
    BROWSE_TIMEOUT = 2

    class << self
      attr_accessor :machines, :browse_thread

      # browse can be used alone to populate the machines list
      def browse
        self.machines = []

        self.browse_thread = Thread.start do
          DNSSD.browse! '_qlab._udp' do |b|
            DNSSD.resolve b.name, b.type, b.domain do |r|
              self.machines << Qcmd::Machine.new(b.name, r.target, r.port)
            end
          end
        end

        sleep BROWSE_TIMEOUT

        Thread.kill(browse_thread) if browse_thread.alive?
      end

      def display options={}
        longest = machines.map {|m| m.name.size}.max

        Qcmd.print
        Qcmd.print "Found #{ machines.size } QLab machine#{ machines.size == 1 ? '' : 's'}"
        Qcmd.print

        machines.each_with_index do |machine, n|
          if Qcmd.debug?
            Qcmd.print "#{ n + 1 }. %-#{ longest + 2 }s %s" % [machine.name, machine.client_string]
          else
            Qcmd.print "#{ n + 1 }. %-#{ longest + 2 }s" % [machine.name]
          end
        end

        Qcmd.print
        Qcmd.print 'type `connect MACHINE` to connect to a machine'
        Qcmd.print
      end

      def browse_and_display options={}
        browse
        if !options[:machine_given] || (options[:machine_given] && !find(options[:machine_name]).nil?)
          display options
        end
      end

      def find machine_name
        machines.find {|m| m.name == machine_name}
      end

      def find_by_index idx
        machines[idx] if idx < machines.size
      end

      def names
        machines.map(&:name)
      end
    end
  end
end
