module = 'factoids'

update = ->
  path = "./plugins/#{module}/storage.json"
  require('fs').writeFile path, JSON.stringify @storage[module]
  true

exports.add = ->
  message = @message.value.split ' '
  command = message[0]
  text = message[1..].join ' '

  if not command
    return @respond 'You should specify the command!'
  else if not text
    return @respond 'You should specify the text!'

  if @storage[module][command]?
    @respond 'Factoid successfully modified!'
  else if @commands[command]?
    # If we have confirmed that it wasn't inserted by factoids, return if it
    # exists anyways.
    @respond 'This command is used internally! You cannot overwrite it!'
    return
  else
    @respond 'Factoid successfully added!'

  @storage[module][command] = text
  update.apply this

exports.delete = ->
  command = @message.value.split(' ')[0]
  if @storage[module][command]?
    @respond 'Factoid successfully deleted!'
    @removeCommands command
    update.apply this
  else
    @respond 'Factoid doesn\'t exist!'

exports._init = ->
  path = require 'path'
  fs = require 'fs'

  # path.existsSync is deprecated. It is now called `fs.existsSync`.
  fs.existsSync ?= path.existsSync

  if not fs.existsSync "./plugins/#{module}/storage.json"
    @log 'Factoids storage not found, creating storage.', 'error'
    fs.writeFileSync "./plugins/#{module}/storage.json", '{}'

  # If factoids are unknown, load them
  @storage[module] ?= require('./storage')
  for command of @storage[module]
    @addCommands command

exports._else = (self) ->
  if @message.command?
    if @storage[module][@message.command]?
      @respond @storage[module][@message.command]