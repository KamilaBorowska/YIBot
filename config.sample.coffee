# List of plugins
Plugins = [
  'eightball'
]

# Servers configuration
exports.config =
  Freenode:
    Type: 'IRC'
    Host: 'irc.freenode.net'
    Channels: [
      # Normal channel
      '#botters'

      # Channel with specific configuration
      '#yibot':
        Prefix: ','
        Plugins: [
            Plugins...
            'math'
        ]
    ]
    NickServ:
      Nick: 'NickServ'
      Password: 'sample-password'

# Used in case variable doesn't exist.
exports.globals =
  IRC:
    Port: 6667
    Nick: 'YIBotClone'
    User: 'yibot'
    Realname: 'My real name'
    Plugins: Plugins
    Owner: /^glitchmr@.*[.]adsl[.]inetia[.]pl$/
    ReactOnInvite: 'Invited by %s.'
    # May be RegExp too if you remember to start it with ^ character!
    Prefix: '@'
  Shell:
    Plugins: Plugins
