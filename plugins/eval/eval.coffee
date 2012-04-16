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
    message = [@message.value]
    colors = @config.Type is 'Shell'
    @respond inspect evaluate.apply(this, message), false, null, colors
  else
    @respond "You aren't my owner!"

exports._init = ->
  if @config.Type is 'Shell'
    @addCommands 'e'
    exports.e = exports.eval