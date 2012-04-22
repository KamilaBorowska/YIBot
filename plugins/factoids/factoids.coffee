update = (config) ->
  path = "./plugins/#{@plugin}/#{config.StorageName ? 'storage'}.json"
  require('fs').writeFile path, JSON.stringify @_.storage
  true

exports.add = (config) ->
  message = @message.value.split ' '
  command = message[0]
  text = message[1..].join ' '

  if not command
    return @respond 'You should specify the command!'
  else if not text
    return @respond 'You should specify the text!'

  if @_.storage[command]?
    @respond 'Factoid successfully modified!'
  else if command in @getCommands()
    # If we have confirmed that it wasn't inserted by factoids, return if it
    # exists anyways.
    @respond 'This command is used internally! You cannot overwrite it!'
    return
  else
    @respond 'Factoid successfully added!'

  @_.storage[command] = text
  update.call this, config

exports.delete = (config) ->
  command = @message.value.split(' ')[0]
  if @_.storage[command]?
    @respond 'Factoid successfully deleted!'
    @removeCommands command
    update.call this, config
  else
    @respond 'Factoid doesn\'t exist!'

exports._channelInit = (config) ->
  path = require 'path'
  fs = require 'fs'

  # path.existsSync is deprecated. It is now called `fs.existsSync`.
  fs.existsSync ?= path.existsSync

  storage = config.StorageName ? 'storage'

  if not fs.existsSync "./plugins/#{@plugin}/#{storage}.json"
    @log 'Factoids storage not found, creating storage.', 'error'
    fs.writeFileSync "./plugins/#{@plugin}/#{storage}.json", '{}'

  # If factoids are unknown, load them
  @_.storage ?= require "./#{storage}"
  for command of @_.storage
    @addCommands command

exports._else = (config) ->
  if @message.command?
    storage = config.StorageName ? 'storage'
    @_.storage ?= require "./#{storage}"
    if @_.storage[@message.command]?
      @respond @_.storage[@message.command]
