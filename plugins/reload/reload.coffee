exports.reload = ->
  if @message.owner
    @reloadModules()
  else
    @respond "You aren't my owner!"