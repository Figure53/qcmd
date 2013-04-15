module Qcmd
  class Handler
    include Qcmd::Plaintext

    # Handle OSC response message from QLab
    def handle message
      Qcmd.debug "([Handler#handle] converting OSC::Message to QLab::Reply)"
      reply = QLab::Reply.new(message)

      Qcmd.debug "(handling #{ reply.to_s })"

      case reply.address
      when %r[/workspaces]
        Qcmd.context.machine.workspaces = reply.data.map {|ws| Qcmd::QLab::Workspace.new(ws)}

        unless Qcmd.quiet?
          print_workspace_list
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
        Qcmd.debug "(received cue list from #{reply.address})"

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

      when %r[/(cue|cue_id)/([^/]+)/[a-zA-Z]+]
        cue_tag = $1
        cue_identifier = $2

        # isolate and fixate on cue so that subsequent messages go to the cue
        if Qcmd.context.workspace.has_cues?
          _cue = Qcmd.context.workspace.cues.find {|cue|
            if cue_tag == 'cue'
              cue.number.to_s == cue_identifier.to_s
            elsif cue_tag == 'cue_id'
              cue.id.to_s == cue_identifier.to_s
            end
          }

          if _cue
            Qcmd.context.cue = _cue
            Qcmd.context.cue_connected = true
          end
        end

        # properties, just print reply data
        result = reply.data

        # simple response
        if result.is_a?(String) || result.is_a?(Numeric)
          print result
        else
          # handle specific reponses
          case reply.address
          when %r[/valuesForKeys]
            Qcmd.debug "[valuesForKeys] received reply #{ reply.to_s }"
            Qcmd.debug "[valuesForKeys] with result #{ result.inspect }"

            keys = result.keys.sort
            table(['Field Name', 'Value'], keys.map {|key|
              [key, result[key]]
            })
          else
            if !result.nil?
              if result.is_a?(Hash) || result.is_a?(Array)
                begin
                  print JSON.pretty_generate(result)
                rescue JSON::GeneratorError
                  Qcmd.debug "([Handler#handle /cue] failed to JSON parse data: #{ result.inspect })"
                  print result.to_s
                end
              else
                print result.to_s
              end
            else
              Qcmd.debug "([Handler#handle /cue] response has no data: #{ reply.to_s })"
              if !reply.status.nil? && reply.status != 'ok'
                print reply.status
              end
            end
          end
        end

      when %r[/thump]
        print reply.data

      else
        Qcmd.debug "(unrecognized message from QLab, cannot handle #{ reply.address })"

        if !reply.status.nil? && reply.status != 'ok'
          Qcmd.print reply.status
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
      Qcmd.print_wrapped('Type `use "WORKSPACE_NAME" PASSCODE` to load a workspace. Passcode is optional.')
      Qcmd.print
    end
  end
end
