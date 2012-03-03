exports.coin = ->
  @respond if Math.floor Math.random() * 2 then 'heads' else 'tails'

exports.random = ->
  match = /^\s*(\d*?)(?:d|\s*)(\d+)\s*$/.exec @message.value
  if match?
    [match, throws, sides] = match

  if !match
    if @config.Prefix instanceof RegExp or not @config.Prefix?
      prefix = ''
    else
      prefix = "#{@config.Prefix}"

    @respond "Syntax: #{prefix}random [throws] [sides]"
    return

  else if throws is ''
    throws = 0
  else if throws > 100000
    @respond 'Seriously, why you need so many throws?'
    return

  result = 0
  if sides is '0'
    result = 0
  else
      for [0...throws]
        result += Math.floor Math.random() * sides + 1
  s = if throws is '1' then '' else 's'
  @respond "You have thrown a #{sides}-sided dice #{throws} time#{s}. " +
           "After summing up everything we get #{result}."