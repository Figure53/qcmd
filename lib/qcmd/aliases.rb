module Qcmd
  class Aliases
    def self.defaults
      @defaults ||= {
        'n' => 'cue $1 name $2',
        # zero-out cue_number
        'zero-out' => (1..48).map {|n| "(cue $1 sliderLevel #{n} 0)"}.join(' '),
        # copy-sliders from_cue_number to_cue_number
        'copy-sliders' => (1..48).map {|n| "(cue $2 sliderLevel #{n} (cue $1 sliderLevel #{n} 0))"}.join(' ')
      }.merge(copy_cue_actions)
    end

    def self.copy_cue_actions
      Hash[
        %w(name notes fileTarget cueTargetNumber cueTargetId preWait duration
           postWait continueMode flagged armed colorName).map do |field|
          [
            "copy-#{ field }",
            "(cue $2 #{ field } (cue $1 #{ field }))"
          ]
        end
      ]
    end
  end
end
