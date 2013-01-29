# This is interface to server. You're expected to extend it. You can also use
# it as reference to bot commands. Your interface should involve server-
# specific things in code itself, instead of sending it to external modules.

class exports.Server
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
  @serverName = ''

  # Configuration of current server
  @config = {}

  # List of channels and nicks. If protocol supports only one channel, insert
  # undefined constant as channel name.
  @channels = {}

  # Storage for various stuff. Your plugins are expected to it using
  # @storage[name], unless those want to affect other plugins behavior.
  #
  # You can use @$ as shortcut (every channel likes money, right?)
  @storage = {}

  # Channel unique storage. It's accessed by @channelStorage[plugin][channel],
  # but you can also use @_ as shortcut (it's just one brick in the wall).
  @channelStorage = {}

  # Just like @channelStorage, except for private messages
  @privateStorage = {}

  # Current plugin storage. You may consider me evil for making punctuation
  # variables in JavaScript (it's not Perl), but I seriously don't care...
  @$ = null

  # Current channel storage.
  @_ = null

  # Name of current plugin
  @plugin = null

  # List of commands supported by this bot
  @commands = {}

  # Load the configuration file
  constructor: (@serverName, @config) ->
    # Constants
    @BOLD = "\x02"
    @ITALICS = "\x16"
    @UNDERLINE = "\x1F"
    @COLOUR = "\x03"
    @NORMAL = "\x0F"

    # Fix bug which causes @channels and @message to be undefined in extended
    # properties
    @channels ?= {}
    @message = {}
    @storage = {}
    @channelStorage = {}
    @privateStorage = {}
    @commands = {}

    if @config.Channels and @config.Channels instanceof Array
      @config.Channels = @toObject @config.Channels

    for property, value of @config
      for channelName, channel of @config.Channels
        channel[property] ?= value

    channelPlugins = for channel, value of @config.Channels
      object = @toObject value.Plugins
      object._channel = channel
      object

    processedPlugins = []
    for plugins in [channelPlugins..., @toObject @config.Plugins]
      for name, config of plugins when name isnt '_channel'
        @plugin = name
        @$ = @storage[name] = {}
        plugin = require "./plugins/#{name}/#{name}"
        # Run init function if it exists in plugin
        if name not in processedPlugins
          plugin._init?.call this, config
          for property of plugin
            if /^[^_$]/.test(property)
              @addCommands property
          processedPlugins.push name

        if plugin._channelInit? and plugins._channel?
          @channelStorage[name] ?= {}
          @channelStorage[name][plugins._channel] ?= {}
          @_ = @channelStorage[name][plugins._channel]
          plugin._channelInit.call this, config


  # When ran, server is expected to try connecting and starting reading data.
  connect: ->

  # This is part of interface. It causes to respond to person who started it,
  # either on public channel if it was on public channel, or on PM if it was
  # PM. It accepts IRC escape sequences.
  respond: (message, me = false) ->

  # This sends message to the channel. Note that on some protocols, public
  # channels are different to PMs. Take care of this while making plugin.
  # If protocol doesn't have concept of channels, throw exception, otherwise
  # return true. If the protocol supports only one channel, ignore channel
  # value. It accepts IRC escape sequences.
  send: (message, channel, me = false) ->

  # This function sends PM to specified user. If protocol doesn't have PMs
  # throw exception, otherwise return true. It accepts IRC escape sequences.
  pm: (message, user, me = false) ->

  # This command is join channel command. It takes "ID" or "name" as
  # argument depending on where you're using it. In case it's impossible,
  # you're expected to throw exception. Otherwise, return true.
  join: (id) ->
    @config.Channels[id] ?= @config

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

    if status of statuses
      console.log("[#{@serverName}] #{statuses[status]} #{msg}")
    else
      throw new Error "Unknown status #{status} (log)."

  loadPlugins: ->
    channelPlugins = @config.Channels[@message?.channel]?.Plugins
    for plugin, config of @toObject channelPlugins or @config.Plugins
      try
        @plugin = plugin
        @$ = @storage[@plugin] ?= {}

        storage = if @message.type is 'private'
          @privateStorage
        else
          @channelStorage

        @_ = if @message.channel
          if not storage[@plugin]?[@message.channel]?
            storage[@plugin] ?= {}
            storage[@plugin][@message.channel] = {}
          storage[@plugin][@message.channel]

        plugin = require("./plugins/#{@plugin}/#{@plugin}")

        # Don't run if it's prepended with _ or $, those are for internal use.
        if @message.command? and /^[^_$]/.test(@message.command)
          return if plugin[@message.command.toLowerCase()]?.call this, config

        return if plugin._else?.call this, config
      catch e
        if @config.Debug
          throw e
        @log e, 'error'


  parseMessage: ->
    # In case of private messages, use global prefix
    prefix = @config.Channels[@message?.channel]?.Prefix ? @config.Prefix
    # If prefix is regexp, check regexp
    if prefix instanceof RegExp and prefix.test(@message.text)
      # If it matches prefix, remove it from text
      withoutPrefix = @message.text.replace(prefix, '')
    else if @message.text.indexOf(prefix) is 0
      withoutPrefix = @message.text.substr(prefix.length)
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
    @commands[@plugin] ?= []
    for command in commands when command not in @commands[@plugin]
      @commands[@plugin].push command

  # Removes commands from list of commands.
  removeCommands: (commands...) ->
    for command in commands
      if command in @commands[@plugin]
        @commands[@plugin].splice @commands[@plugin].indexOf(command), 1

  getCommands: (channel = @message.channel) ->
    plugins = []
    channelPlugins = @config.Channels[channel]?.Plugins
    for plugin of @toObject channelPlugins ? @config.Plugins
      continue unless @commands[plugin]?
      for plug in @commands[plugin]
        if plug not in plugins
          plugins.push plug
    plugins

  # Parses through pastebin module in order to load shortened version of text
  pastebin: (text, channel, context) =>
    try
      pastebin = require './plugins/pastebin/pastebin'
      pastebin._pastebin.apply this, arguments
    catch e
      @[context] 'Too long response.', channel

  reloadModules: (every = yes) ->
    if every
      for name, server of servers
        server.reloadModules no
    else
      for key of require.cache
        delete require.cache[key]
      exports.Server.call this, @serverName, @config

  toObject: (array) ->
    object = {}
    for value in array
      if value instanceof Object
        for key, val of value
          object[key] = val
      else
        object[value] = {}
    object
