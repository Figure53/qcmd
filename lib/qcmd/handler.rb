module Qcmd
  class Handler
    include Qcmd::Plaintext

    # Handle OSC response message from QLab
    def handle message
      reply = QLab::Reply.new(message)

      Qcmd.debug "(handling #{ reply.address } #{ reply.data.inspect })"

      case reply.address
      when %r[/workspaces]
        Qcmd.context.machine.workspaces = reply.data.map {|ws| Qcmd::QLab::Workspace.new(ws)}

        unless Qcmd.quiet?
          Qcmd.context.print_workspace_list
        end

      when %r[/workspace/[^/]+/connect]
        # connecting to a workspace
        if reply.data == 'badpass'
          print 'failed to connect to workspace, bad passcode or no passcode given'
          Qcmd.context.disconnect_workspace
        elsif reply.data == 'ok'
          print 'connected to workspace'
          Qcmd.context.workspace_connected = true
        end

      when %r[/cueLists]
        Qcmd.debug "(received cueLists)"

        # load global cue list
        Qcmd.context.workspace.cue_lists = reply.data.map {|cue_list| Qcmd::QLab::CueList.new(cue_list)}

      when %r[/(selectedCues|runningCues|runningOrPausedCues)]
        cues = reply.data.map {|cue_list|
          unpack_cues(cue_list)
        }.compact.flatten

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

      when %r[/(cue|cue_id)/[^/]+/[a-zA-Z]+]
        # properties, just print reply data
        result = reply.data
        if result.is_a?(String) || result.is_a?(Numeric)
          print result
        else
          case reply.address
          when %r[/valuesForKeys]
            print reply.to_s
            print result.inspect

            keys = result.keys.sort
            table(['Field Name', 'Value'], keys.map {|key|
              [key, result[key]]
            })
          else
            begin
              print JSON.pretty_generate(result)
            rescue JSON::GeneratorError
              print result.to_s
            end
          end
        end

      when %r[/thump]
        print reply.data

      else
        Qcmd.debug "(unrecognized message from QLab, cannot handle #{ reply.address })"
      end
    end

    private

    # return a possibly nested list of cues
    def unpack_cues cuelist
      cuelist['cues'].map {|cue|
        Qcmd::QLab::Cue.new(cue)
      }
    end
  end
end
