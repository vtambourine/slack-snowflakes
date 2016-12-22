require 'net/http'
require 'uri'
require 'json'
require 'faye/websocket'
require 'eventmachine'

class Snowflakes

  SLACK_BOT_TOKEN = ENV['SLACK_BOT_TOKEN']

  REACTIONS = ['snowflake', 'snowman', 'christmas_tree']

  @@id = 0

  @@ws = nil

  def initialize
    meta_raw = Net::HTTP.get URI("https://slack.com/api/rtm.start?token=#{SLACK_BOT_TOKEN}")
    meta = JSON.parse(meta_raw)
    socket = meta['url']
    Snowflakes::WebSocketClient.new(socket)
  end

  class WebSocketClient
    def initialize(url)
      @url = url

      EM.run do
        @@ws = Faye::WebSocket::Client.new(url)

        @@ws.on :open do |event|
          p [:open]
        end

        @@ws.on :message do |event|
          data = JSON.parse(event.data)
          type = data['type']
          p [:message, type, data]

          case type
            when 'message'
              channel = data['channel']
              timestamp = data['ts']
              reaction = REACTIONS.sample

              uri = URI("https://slack.com/api/reactions.add?name=#{reaction}&channel=#{channel}&timestamp=#{timestamp}&token=#{SLACK_BOT_TOKEN}")
              Net::HTTP.get(uri)
            when 'reconnect_url'
              @url = data['url']
            else
              # nil
          end
        end

        @@ws.on :close do |event|
          p [:close, event.code, event.reason]
          @@ws = Snowflakes::WebSocketClient.new(@url)
        end
      end
      # attach all events
    end
  end
end

Snowflakes.new
