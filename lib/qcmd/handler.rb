module Qcmd
  class Handler
    include Qcmd::Plaintext

    def handle reply
      Qcmd.debug "(handling #{ reply })"

      case reply.address
      when %r[/workspaces]
        Qcmd.context.machine.workspaces = reply.data.map {|ws| Qcmd::QLab::Workspace.new(ws)}

        print centered_text(" Workspaces ", '-')
        print
        Qcmd.context.machine.workspaces.each_with_index do |ws, n|
          print "#{ n + 1 }. #{ ws.name }"
        end

        print
        print wrapped_text('Type `use "WORKSPACE_NAME" PASSCODE` to load a workspace. ' +
                           'Only enter a passcode if your workspace uses one')
        print

      when %r[/workspace/[^/]+/connect]
        # connecting to a workspace
        if reply.data == 'badpass'
          print 'failed to connect to workspace'
          Qcmd.context.disconnect_workspace
        elsif reply.data == 'ok'
          print 'connected to workspace'
          Qcmd.context.workspace_connected = true
        end

      when %r[/cueLists]
        Qcmd.debug "(received cueLists)"
        # looking for cues here
        Qcmd.context.workspace.cues = cues = reply.data.map {|cue_list|
          cue_list['cues'].map {|cue| Qcmd::QLab::Cue.new(cue)}
        }.compact.flatten
        print "loaded #{pluralize cues.size, 'cue'}"

      when %r[/(cue|cue_id)/[^/]+/[a-zA-Z]+]
        # properties, just print reply data
        print reply.data

      else
        Qcmd.debug "(unrecognized message from QLab, cannot handle #{ reply.address })"
      end
    end
  end
end
