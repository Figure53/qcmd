module Qcmd
  class Aliases
    def self.defaults
      @defaults ||= {
        'n' => 'cue $1 name $2',
        # zero-out cue_number
        'zero-out' => '(log-silent)' +
                      (1..48).map {|n| "(cue $1 sliderLevel #{n} 0)"}.join(' ') +
                      '(log-noisy) (echo "set slider levels for cue $1 to all zeros")',
        # copy-sliders from_cue_number to_cue_number
        'copy-sliders' => '(log-silent)' +
                          (1..48).map {|n| "(cue $2 sliderLevel #{n} (cue $1 sliderLevel #{n}))"}.join(' ') +
                          '(log-noisy) (echo "copied slider levels from cue $1 to cue $2")',
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
