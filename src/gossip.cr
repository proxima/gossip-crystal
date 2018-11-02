require "http/web_socket"
require "json"

module Gossip
  VERSION      = "0.1.0"
  LOGIN_LOGOUT = %w(player_login player_logout)

  class Client
    @game_name : String = "Test MUD"
    @client_id : String = ""
    @client_secret : String = ""

    {% for verb in LOGIN_LOGOUT %}
      getter {{verb.id}} : Channel(String) = Channel(String).new
    {% end %}

    getter broadcast : Channel(JSON::Any) = Channel(JSON::Any).new

    property player_list : Proc(Array(String)) = ->{ [] of String }
    property verbose : Bool = false

    def initialize(game_name, client_id, client_secret)
      @game_name = game_name
      @client_id = client_id
      @client_secret = client_secret
    end

    def authenticate
      return JSON.build do |json|
        json.object do
          json.field "event", "authenticate"
          json.field "payload" do
            json.object do
              json.field "client_id", @client_id
              json.field "client_secret", @client_secret
              json.field "supports" do
                json.array do
                  json.string "channels"
                  json.string "players"
                  json.string "tells"
                  json.string "games"
                end
              end
              json.field "channels" do
                json.array do
                  json.string "gossip"
                  json.string "testing"
                  json.string "announcements"
                end
              end
              json.field "version", "2.2.0"
              json.field "user_agent", "crystal-gossip #{Gossip::VERSION}"
            end
          end
        end
      end
    end

    def pong
      return JSON.build do |json|
        json.object do
          json.field "event", "heartbeat"
          json.field "payload" do
            json.object do
              json.field "players" do
                json.array do
                  @player_list.call.map do |p|
                    json.string p
                  end
                end
              end
            end
          end
        end
      end
    end

    {% for verb in LOGIN_LOGOUT %}
    def {{verb.id}}_json(player : String)
      return JSON.build do |json|
        json.object do
          {% if verb == "player_login" %}
            json.field "event", "players/sign-in"
          {% elsif verb == "player_logout" %}
            json.field "event", "players/sign-out"
          {% end %}
          json.field "payload" do
            json.object do
              json.field "name", player
            end
          end
        end
      end
    end
    {% end %}

    def run
      ws = HTTP::WebSocket.new(URI.parse("wss://gossip.haus/socket"))

      {% for verb in LOGIN_LOGOUT %}
      spawn do
        loop do
          ws.send({{verb.id}}_json(@{{verb.id}}.receive))
        end
      end
      {% end %}

      ws.on_close do |message|
        puts "Close: #{message}" if verbose
      end

      ws.on_message do |message|
        puts "Message: #{message}" if verbose

        response = JSON.parse(message)
        event_type = response["event"]

        case event_type.as_s
        when /authenticate/
          puts "[Gossip] Authenticated" if verbose
        when /heartbeat/
          puts "[Gossip] Pong!" if verbose
          ws.send pong
        when /channels\/broadcast/
          spawn @broadcast.send response["payload"]
        else
          puts "[Gossip] Unhandled event: #{event_type}" if verbose
        end
      end

      ws.send authenticate

      ws.run
    end
  end
end
