module Qcmd
  class Command < Struct.new(:name, :response)
  end

  module Commands

    # name, response

    class << self
      def wait?(command)
        %w(cues workspaces name).include?(command)
      end

      def root
        @root ||= cmap [
          ['connect', true]
        ]
      end

      def machine
        @machine ||= cmap [
          ['workspaces', true]
        ]
      end

      def workspace
        @workspace ||= cmap [
          ['cues', true],
          ['go', false]
        ]
      end

      def cue
        @cue ||= cmap [
          ['name', true],
          ['go', false]
        ]
      end

      private

      def cmap commands
        commands.map {|c| Command.new(c)}
      end
    end
  end
end
