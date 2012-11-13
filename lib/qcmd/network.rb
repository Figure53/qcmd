require 'dnssd'

module Qcmd
  class Network
    class << self
      attr_accessor :machines, :browser

      def browse
        self.machines = []
        self.browser = DNSSD.browse '_qlab._udp' do |b|
          DNSSD.resolve b.name, b.type, b.domain do |r|
            self.machines << Qcmd::Machine.new(b.name, r.target, r.port)
          end
        end
      end

      def display
        machines.each do |machine|
          Qcmd.print '-- machine --'
          Qcmd.print "%-12s%s" % [machine.name, machine.client_string]
          Qcmd.print
        end
      end

      def browse_and_display
        browse
        display
      end
    end
  end
end
