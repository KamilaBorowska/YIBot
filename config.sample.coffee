# List of plugins
Plugins = [
  # Normal plugin
  'eightball'
  # Plugin with settings (it has ":" character at end)
  'uno':
    channel: '#uno'
]

# Servers configuration
exports.config =
  Freenode:
    Type: 'IRC'
    Host: 'irc.freenode.net'
    Channels: [
      '#yibot'
    ]

# Used in case variable doesn't exist.
exports.globals =
  IRC:
    Port: 6667
    Nick: 'YIBotClone'
    User: 'yibot'
    Plugins: Plugins
    Owner: /^glitchmr@.*[.]adsl[.]inetia[.]pl$/
    ReactOnInvite: 'Invited by %s.'
    # May be RegExp too if you remember to start it with ^ character!
    Prefix: '@'
  Shell:
    Plugins: Plugins