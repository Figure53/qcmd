module Qcmd
  class Configuration
    class << self
      attr_accessor :current_room

      def method_missing(method)
        config[method.to_s]
      end

      def config
        @config ||= YAML.load(File.open(config_file))[current_room]
      end

      def history
        @history ||= begin
                       f = File.new(history_file, 'a')
                       f.sync = true
                       f
                     end
      end

      def log
        @log ||= begin
                   f = File.new(log_file, 'a')
                   f.sync = true
                   f
                 end
      end

      def config_file
        File.join(Dir.home(current_user), ".qcmd.yml")
      end

      def history_file
        File.join(Dir.home(current_user), ".qcmd-history.log")
      end

      def log_file
        File.join(Dir.home(current_user), ".qcmd.log")
      end

      def current_user
        @current_user ||= ::Etc.getlogin
      end
    end
  end
end
