module Qcmd
  VERSION = "0.1.14"

  class << self
    def installed_version
      Gem.loaded_specs["qcmd"].version
    end

    def available_version
      @available_version ||= begin
                              require "net/http"
                              require "uri"

                              begin
                                uri = URI.parse("http://rubygems.org/api/v1/gems/qcmd.json")

                                # Shortcut
                                response = Net::HTTP.get_response(uri)
                              rescue => ex
                                Qcmd.print "couldn't load remote qcmd version: #{ ex.message }"
                                return false
                              end

                              begin
                                JSON.parse(response.body)['version']
                              rescue => ex
                                Qcmd.print "couldn't load remote qcmd version: #{ ex.message }"
                                false
                              end
                             end
    end
  end
end
