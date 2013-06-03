module Qcmd
  VERSION = "0.1.14"

  class << self
    def installed_version
      Gem.loaded_specs["qcmd"].version
    end

    def rubygems_uri
      @rubygems_uri ||= URI.parse("http://rubygems.org/api/v1/gems/qcmd.json")
    end

    def available_version
      @available_version ||= begin
                              require "net/http"
                              require "uri"

                              begin
                                # Shortcut
                                response = Net::HTTP.get_response(rubygems_uri)
                              rescue => ex
                                Qcmd.debug "error loading #{ rubygems_uri }"
                                Qcmd.debug "couldn't load remote qcmd version: #{ ex.message }"
                                return false
                              end

                              begin
                                JSON.parse(response.body)['version']
                              rescue => ex
                                Qcmd.debug "error parsing #{ rubygems_uri }"
                                Qcmd.debug "couldn't parse remote qcmd version: #{ ex.message }"
                                false
                              end
                             end
    end
  end
end
