# gossip

Gossip is a shard for integrating MUDs with the [Gossip](https://gossip.haus/) inter-mud chat network.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  gossip:
    github: proxima/gossip
```

## Usage

```crystal
require "gossip"

client = Gossip::Client.new
client.setup "mud_name", "client-id", "client-secret"
spawn client.run
```

## Enable verbose logging

```crystal
client.verbose = true
```

## Optionally, you can provide Gossip::Client a Proc which returns the MUD's online players. 

```crystal
client.player_list = ->{ ["Player1", "Player2"] }
```

or

```crystal
client.player_list = ->{ acquire_player_list_somehow(); }
```

## You can also use the client to inform Gossip of login/logoffs in real-time.

```crystal
client.player_login.send "Player Two"
client.player_logoff.send "Player One"
```

## Listen to broadcasts from other MUDs

```crystal
spawn do
  loop do
    msg = client.broadcast.receive
  end
end
```

## Development

TODO: tells (send/receive)
TODO: reconnects, raise errors when disconnected

## Contributing

1. Fork it (<https://github.com/your-github-user/gossip/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [proxima](https://github.com/proxima) Christopher Lee - creator, maintainer
