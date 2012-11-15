require 'dnssd'

module Qcmd
  class Network
    BROWSE_TIMEOUT = 10

    class << self
      attr_accessor :machines, :browse_thread

      def browse
        self.machines = []
        self.browse_thread = Thread.start do
          DNSSD.browse! '_qlab._udp' do |b|
            DNSSD.resolve b.name, b.type, b.domain do |r|
              self.machines << Qcmd::Machine.new(b.name, r.target, r.port)
            end
          end
        end

        naps = 0
        changed = false
        previous = 0

        # sleep for 3 seconds
        while naps < BROWSE_TIMEOUT
          sleep 0.1
          naps += 1

          if machines.size != previous
            puts "found #{ machines.size } QLab machine#{ machines.size == 1 ? '' : 's'}"
            previous = machines.size
          end
        end

        self.browse_thread.kill
      end

      def display
        longest = machines.map {|m| m.name.size}.max
        Qcmd.print
        machines.each_with_index do |machine, n|
          if Qcmd.debug?
            Qcmd.print "#{ n + 1 }. %-#{ longest + 2 }s%s" % [machine.name, machine.client_string]
          else
            Qcmd.print "#{ n + 1 }. %-#{ longest + 2 }s" % [machine.name]
          end
        end

        Qcmd.print
        Qcmd.print 'type `connect MACHINE` to connect to a machine'
        Qcmd.print
      end

      def browse_and_display
        browse
        display
      end

      def find machine_name
        machines.find {|m| m.name == machine_name}
      end

      def names
        machines.map(&:name)
      end
    end
  end
end
