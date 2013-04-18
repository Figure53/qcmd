require 'fileutils'

module Qcmd
  class Configuration
    class << self
      def qcmd_directory
        ".qcmd"
      end

      def home_directory
        @home_directory ||= begin
                              full_path = File.join(File.expand_path('~'), qcmd_directory)
                              begin
                                if !File.exists?(full_path)
                                  FileUtils.mkdir_p(full_path)
                                end
                                full_path
                              rescue => ex
                                puts "Failed to create qcmd's home directory at #{ full_path }"
                                puts ex.message

                                exit 1
                              end
                            end
      end

      def open_file_for_appending(fname)
         f = File.new(fname, 'a')
         f.sync = true
         f
      end

      def config
        @config ||= begin
                      if !File.exists?(config_file)
                        File.open(config_file, 'w') {|f|
                          default = JSON.pretty_generate({'aliases' => Qcmd::Aliases.defaults})
                          Qcmd.debug "([Configuration config] writing defaults: #{ default })"
                          f.write default
                        }
                      end

                      JSON.load(File.open(config_file))
                    end
      end

      def update key, value
        config[key] = value
        save
      end

      def save
        File.open(config_file, 'w') {|conf_file|
          conf_file.write(JSON.pretty_generate(config))
        }
      end

      # not really config file things, but related to config & settings storage

      def history
        @history ||= open_file_for_appending(history_file)
      end

      def log
        @log ||= open_file_for_appending(log_file)
      end

      # and the actual files

      def config_file
        File.join(home_directory, "settings.json")
      end

      def history_file
        File.join(home_directory, "history.log")
      end

      def log_file
        File.join(home_directory, "debug.log")
      end
    end
  end
end
