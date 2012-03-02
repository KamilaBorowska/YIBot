# List of plugins
Plugins = [
  'eightball'
  'factoids'
  'eval'
  'math'
  'random'
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
    # May be RegExp too if you remember to start it with ^!
    Prefix: '@'
  Shell:
    Plugins: Plugins