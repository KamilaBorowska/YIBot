# Note - don't use this with other types. This type is supposed to be used
# only for debugging and shell piping. Thanks :).

{Server} = require('../server')
repl = require('repl')

class exports.Shell extends Server
  connect: ->
    process.stderr.write "[#{@name}] <<< "

    process.stdin.resume()
    process.stdin.setEncoding 'utf8'

    process.stdin.on 'data', (data) =>
      @message.text = data.replace(/^\s+|\s+$/, '')
      # No prefixes needed
      @message.type = 'private'
      # You can expect that everybody who has access to shell is owner
      @message.owner = true

      # When variables are initialized, give control to plugins
      @parseMessage()
      @loadPlugins()

      @message = {}

      process.stderr.write "[#{@name}] <<< "

    process.stdin.on 'error', ->

  # Those commands are identical in this protocol
  respond: (message, pm) -> @log message
  send: (message, blah, pm) -> @log message
  pm: (message, blah, pm) -> @log message

  log: (message, pm) =>
    status = if pm then '***' else '>>>'
    process.stderr.write "[#{@name}] #{status} "
    console.log message

  join: -> throw new Error 'You cannot join while using shell pseudo-protocol.'
  part: -> throw new Error 'You cannot part while using shell pseudo-protocol.'
  nick: -> throw new Error 'You cannot part while using shell pseudo-protocol.'
