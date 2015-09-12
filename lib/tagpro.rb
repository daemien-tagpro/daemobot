require 'httparty'

module Daemobot
  class TagPro
    HTTP_BASE = 'http://'
    GROUP_URI = '/groups/create'
    KOALABEAST_URI = 'tagpro-%{server}.koalabeast.com'
    JUKEJUICE_URI = '%{server}.jukejuice.com'
    NEWCOMPTE_URI = '%{server}.newcompte.fr'
    SERVERS = [NEWCOMPTE_URI, JUKEJUICE_URI, KOALABEAST_URI]

    def initialize
      @mutex = Mutex.new
    end

    def create_group(server, publ: false)
      @mutex.synchronize {
        group_url = make_group server, publ: publ
        if group_url
          Daemobot::MessageBuilder.group_created(group_url)
        else
          Daemobot::MessageBuilder.unknown_server(server)
        end
      }
    end

  private

    def build_urls(server)
      SERVERS.map do |url|
        HTTP_BASE + ( url % { server: server } ) + GROUP_URI
      end
    end

    def group_request(url, publ)
      begin
        res = HTTParty.post url, follow_redirects: false, :body => { public: publ }
        url.sub(/\/groups.*$/, res.response['location']) if res.code == 302
      rescue SocketError
        # Rescue from inexistent servers and locations
        # If it isn't valid, ignore it, nil will be returned
        # Otherwise the location will be sent
        nil
      rescue Errno::ECONNREFUSED
        # Old, inactive servers still have active DNS rules
        # However, these don't give a socket error, but instead
        # a connection refused error. Handle those the same way
        nil
      rescue URI::InvalidURIError
        # Don't care about invalid URIs
        # Don't do anything
        nil
      end
    end

    def make_group(server, publ: false)
      res = ""
      build_urls(server).detect do |url|
        res = group_request(url, publ)
      end
      res
    end
  end
end
