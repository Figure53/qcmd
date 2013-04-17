module Qcmd
  class Handler
    class << self
      include Qcmd::Plaintext

      # Handle OSC response message from QLab
      def handle message
        Qcmd.debug "([Handler handle] converting OSC::Message to QLab::Reply)"
        reply = QLab::Reply.new(message)

        Qcmd.debug "([Handler handle]handling #{ reply.to_s })"

        case reply.address
        when %r[/cueLists]
          Qcmd.debug "([Handler handle]received cueLists)"

          # load global cue list
          Qcmd.context.workspace.cue_lists = reply.data.map {|cue_list| Qcmd::QLab::CueList.new(cue_list)}

        when %r[/(selectedCues|runningCues|runningOrPausedCues)]
          Qcmd.debug "([Handler handle] received cue list from #{reply.address})"

          if reply.has_data?
            cues = reply.data.map {|cue| Qcmd::QLab::Cue.new(cue)}

            if cues.size > 0
              title = case reply.address
                      when /selectedCues/;        "Selected Cues"
                      when /runningCues/;         "Running Cues"
                      when /runningOrPausedCues/; "Running or Paused Cues"
                      end

              print
              print centered_text(" #{title} ", '-')
              table(['Number', 'Id', 'Name', 'Type'], cues.map {|cue|
                [cue.number, cue.id, cue.name, cue.type]
              })
              print
            else
              print "no cues found"
            end
          end

        when %r[/thump]
          print reply.data

        else
          Qcmd.debug "([Handler handle] unrecognized message from QLab, cannot handle #{ reply.address })"

          if !reply.status.nil? && reply.status != 'ok'
            print reply.status
          end
        end
      end

      def print_workspace_list
        if Qcmd.context.machine.workspaces.nil? || Qcmd.context.machine.workspaces.empty?
          Qcmd.print "there are no workspaces! you're gonna have a bad time :("
          return
        end

        Qcmd.print Qcmd.centered_text(" Workspaces ", '-')
        Qcmd.print

        Qcmd.context.machine.workspaces.each_with_index do |ws, n|
          Qcmd.print "#{ n + 1 }. #{ ws.name }#{ ws.passcode? ? ' [PROTECTED]' : ''}"
        end

        Qcmd.print
        Qcmd.print_wrapped('Type `use "WORKSPACE_NAME" PASSCODE` to load a workspace. Passcode is required if workspace is [PROTECTED].')
        Qcmd.print
      end
    end
  end
end
