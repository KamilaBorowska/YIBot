exports.coin = ->
  @respond if Math.floor Math.random() * 2 then 'heads' else 'tails'

exports.random = ->
  match = /^(\d*?)[d ]?(\d+)$/.exec @message.value
  if match?
    [match, throws, sides] = match

  if !match
    if @config.Prefix instanceof RegExp or not @config.Prefix?
      prefix = ''
    else
      prefix = "#{@config.Prefix}"

    @respond "Syntax: #{prefix}random [throws] [sides]"
  else if throws is ''
    throws = '1'
  else if throws > 100000
    @respond 'Seriously, why you need so many throws?'
    return

  result = 0
  for [1..throws]
    result += Math.floor Math.random() * sides + 1
  s = if throws is '1' then '' else 's'
  @respond "You have thrown a #{sides}-sided dice #{throws} time#{s}. " +
           "After summing up everything we get #{result}."