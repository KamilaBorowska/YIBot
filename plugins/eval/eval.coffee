{inspect} = require 'util'

evaluate = (code) ->
  try
    # \n is needed to avoid problems with single-line comments
    eval "(#{code}\n)"
  catch exception
    if exception.name is 'SyntaxError'
      try
        eval code
      catch exception
        exception
    else
      exception

exports.eval = ->
  if @message.owner
    colors = @config.Type is 'Shell'
    @respond inspect evaluate(@message.value), false, 2, colors
  else
    @respond "You aren't my owner!"

exports._init = ->
  if @config.Type is 'Shell'
    @addCommands 'e'
    exports.e = exports.eval