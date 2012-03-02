# This is interface to server. You're expected to extend it. You can also use
# it as reference to bot commands. Your interface should involve server-
# specific things in code itself, instead of sending it to external modules.

class Server
  # Your current nick
  @nick = ''

  # When the message is got, put object will following construction there.
  # Otherwise, make it empty. You can add protocol specific fields if you
  # want.
  #
  # {
  #   text: '!yib Hello world!'
  #   command: 'Hello'
  #   value: 'world!'
  #   channel: '#test'
  #   nick: 'TestUser'
  #   owner: false
  #   type: 'message' # might be 'join', 'part', 'quit', 'nick', 'private',
  #                   # 'message', 'other' or any other implementation-
  #                   # specific type
  # }
  @message = {}

  # Name of server which should be modified by constructor.
  @name = ''

  # Configuration of current server
  @config = {}

  # List of channels and nicks. If protocol supports only one channel, insert
  # undefined constant as channel name.
  @channels = {}

  # Storage for various stuff. Your plugins are expected to it using
  # @storage[name], unless those want to affect other plugins behavior.
  #
  # If plugins want to do it globally, the best guess would be variable
  # global.storage[name] which is technically global and can be used
  # anwhere :). This is node, so global should work. Don't use window or any
  # other kind of global object you can think of (window is not defined and
  # isn't global, sorry)...
  @storage = {}

  # List of commands supported by this bot
  @commands = []

  # Load the configuration file
  constructor: (@name, @config) ->
    # Fix bug which causes @channels and @message to be undefined in extended
    # properties
    @channels = {}
    @message = {}
    @storage = {}
    @commands = []

    # Run init function if it exists in plugin
    for plugin in @config.Plugins
      plugin = require("./plugins/#{plugin}/#{plugin}")
      plugin._init?.apply this
      for property of plugin
        if /^[^_$]/.test(property)
          @addCommands property

  # When ran, server is expected to try connecting and starting reading data.
  connect: ->

  # This is part of interface. It causes to respond to person who started it,
  # either on public channel if it was on public channel, or on PM if it was
  # PM.
  respond: (message, me = false) ->

  # This sends message to the channel. Note that on some protocols, public
  # channels are different to PMs. Take care of this while making plugin.
  # If protocol doesn't have concept of channels, throw exception, otherwise
  # return true. If the protocol supports only one channel, ignore channel
  # value.
  send: (message, channel, me = false) ->

  # This function sends PM to specified user. If protocol doesn't have PMs
  # throw exception, otherwise return true.
  pm: (message, user, me = false) ->

  # This command is join channel command. It takes "ID" or "name" as
  # argument depending on where you're using it. In case it's impossible,
  # you're expected to throw exception. Otherwise, return true.
  join: (id) ->

  # This is part command. It causes client to leave the channel. If it's
  # impossible throw exception, else return true.
  part: (id) ->

  # This is change nick command. If it's impossible or would involve
  # registration of another account throw exception. Otherwise return
  # true.
  nick: (nick) ->

  # Call this function to log data which is received/sent
  log: (msg, status = 'read') ->
    statuses =
      'read': '>>>'
      'write': '<<<'
      'error': '!!!'

    if statuses[status]?
      console.log("[#{@name}] #{statuses[status]} #{msg}")
    else
      throw new Error "Unknown status #{status} (log)."

  loadPlugins: ->
    for plugin in @config.Plugins
      try
        plugin = require("./plugins/#{plugin}/#{plugin}")

        # Don't run if it's prepended with _ or $, those are for internal use.
        if @message.command? and /^[^_$]/.test(@message.command)
          break if plugin[@message.command.toLowerCase()]?.apply this

        break if plugin._else?.apply this
      catch e
        throw e if @config.Debug
        @log e, 'error'

  parseMessage: ->
    # If prefix is regexp, check regexp
    if @config.Prefix instanceof RegExp and @config.Prefix.test(@message.text)
      # If it matches prefix, remove it from text
      withoutPrefix = @message.text.replace(@config.Prefix, '')
    else if @message.text.indexOf(@config.Prefix) is 0
      withoutPrefix = @message.text.substr(@config.Prefix.length)
    else if @message.type is 'private'
      withoutPrefix = @message.text

    if withoutPrefix?
      message = withoutPrefix.split(' ')
      @message.command = message[0]
      @message.value = message[1..].join(' ')

  # Adds commands to list of commands. You don't need to activate this
  # function for exported functions with normal names, this command was added
  # for modules like "factoids" where commands aren't known before using
  # "_else".
  addCommands: (commands...) ->
    for command in commands
      if command not in @commands
        @commands.push command

  # Removes commands from list of commands.
  removeCommands: (commands...) ->
    for command in commands
      if command in @commands
        @commands.remove command
      else
        throw new Error 'Unknown command!'

  # Parses through pastebin module in order to load shortened version of text
  pastebin: (text, channel, context) =>
    try
      pastebin = require './plugins/pastebin/pastebin'
      pastebin._pastebin.apply this, arguments
    catch e
      @[context] 'Too long response.', channel

exports.Server = Server