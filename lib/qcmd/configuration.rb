module Qcmd
  class Configuration
    class << self
      attr_accessor :current_room

      def method_missing(method)
        config[method.to_s]
      end

      def config
        @config ||= YAML.load(File.open(config_file))
      end

      def history
        @history ||= open_file_for_appending(history_file)
      end

      def log
        @log ||= open_file_for_appending(log_file)
      end

      def config_file
        File.join(home_directory, ".qcmd.yml")
      end

      def history_file
        File.join(home_directory, ".qcmd-history.log")
      end

      def log_file
        File.join(home_directory, ".qcmd.log")
      end

      def home_directory
        @home_directory ||= File.expand_path('~')
      end

      def open_file_for_appending(fname)
         f = File.new(fname, 'a')
         f.sync = true
         f
      end
    end
  end
end
