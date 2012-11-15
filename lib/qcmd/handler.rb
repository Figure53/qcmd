module Qcmd
  class Handler
    include Qcmd::Plaintext

    def handle message, data
      case message
      when %r[/workspaces]
        Qcmd.context.machine.workspaces = data.map {|ws| Qcmd::QLab::Workspace.new(ws)}

        print centered_text(" Workspaces ", '-')
        print
        Qcmd.context.machine.workspaces.each_with_index do |ws, n|
          print "#{ n + 1 }. #{ ws.name }"
        end

        print
        message = 'type `use "WORKSPACE_NAME" PASSCODE` or `use WORKSPACE_NUMBER PASSCODE` to load a workspace' +
                  'only enter a passcode if your workspace uses one'
        print wrapped_text(message)
        print
      when %r[/workspace/[^/]+/connect]
        # connecting to a workspace
        if data == 'badpass'
          Qcmd.context.workspace = nil
          print 'failed to connect to workspace'
        elsif data == 'ok'
          print 'connected to workspace'
        end
      when %r[/cueLists]
        Qcmd.debug "(received cueLists)"
        # looking for cues here
        Qcmd.context.workspace.cues = cues = data.map {|cue_list|
          cue_list['cues'].map {|cue| Qcmd::QLab::Cue.new(cue)}
        }.compact.flatten
        print "loaded #{pluralize cues.size, 'cue'}"
      else
        Qcmd.debug "(unrecognized message, cannot handle #{ message })"
      end
    end
  end
end
