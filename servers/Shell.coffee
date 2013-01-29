# Note - don't use this with other types. This type is supposed to be used
# only for debugging and shell piping. Thanks :).

{Server} = require('../server')
repl = require('repl')
ircRegExp = /([\x02\x0F\x1A\x1F])|\x03(\d+,(\d+))?/

class exports.Shell extends Server
  connect: ->
    @currentNick = 'Bot'

    process.stderr.write "[#{@serverName}] <<< "

    process.stdin.resume()
    process.stdin.setEncoding 'utf8'

    process.stdin.on 'data', (data) =>
      @message.text = data.trim()
      # No prefixes needed
      @message.type = 'private'
      # You can expect that everybody who has access to shell is owner
      @message.owner = true
      # Your nick
      @message.nick = 'You'

      # When variables are initialized, give control to plugins
      @parseMessage()
      @loadPlugins()

      @message = {}

      process.stderr.write "[#{@serverName}] <<< "

    process.stdin.on 'error', ->

  # Those commands are identical in this protocol
  respond: (message, pm) -> @log message
  send: (message, blah, pm) -> @log message
  pm: (message, blah, pm) -> @log message

  log: (message, pm) =>
    colors = [
      15 # bright white
      0 # black
      4 # blue
      2 # green
      1 # red
      9 # bright red
      5 # Magneta
      3 # yellow
      11 # bright yellow
      10 # bright red
      6 # cyan
      14 # bright cyan
      12 # bright blue
      13 # bright magenta
      8 # bright black
      7 # white
    ]
    status = if pm then '***' else '>>>'
    process.stderr.write "[#{@serverName}] #{status} "

    bold = no
    italics = no
    underline = no
    color = -1
    background = -1
    console.log message.replace ircRegExp, (string, base, fg, bg) =>
      if base?
        switch base
          when @BOLD
            bold = not bold
            if bold then "\x1B]1m" else "\x1B]2m"
          when @ITALICS
            italics = not italics
            if italics then "\x1B]3m" else "\x1B]23m"
          when @UNDERLINE
            underline = not underline
            if underline then "\x1B]4m" else "\x1B]24m"
          when @NORMAL
            bold = no
            italics = no
            underline = no
            color = -1
            background = -1
            "\x1B]0m"
      else
        # We have colors!
        if bg?
          background = colors[bg] & 8
        if fg?
          color = colors[fg] & 8
        else
          color = 9
          background = 9




  join: -> throw new Error 'You cannot join while using shell pseudo-protocol.'
  part: -> throw new Error 'You cannot part while using shell pseudo-protocol.'
  nick: -> throw new Error 'You cannot change nick while using shell pseudo-protocol.'
