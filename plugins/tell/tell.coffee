# I know. It's complex regular expression.
regex = /^\s*(\S*)\s*(?:that\s*)?(.*?)(?:\s*on\s*(\S*)\s*)?$/i

exports.tell = ->
  result = regex.exec @message.value
  return unless result?

  [full, person, text, chan] = result
  realCasePerson = person
  person = person.toLowerCase()
  channel = chan ? @message.channel

  if @channels[channel]
    nicks = (nick.toLowerCase() for nick in @channels[channel])

  @respond if @message.type isnt 'message' and not chan[3]?
    'You should specify the channel by using on [CHANNEL].'
  else if not @channels[channel]
    "I don't know this channel to begin with."
  else if @channels[channel] and person in nicks
    if chan?
      "He is already in mentioned channel. Why you won't tell him directly?"
    else
      "He is already in this channel. Just wait."
  else
    message =
      nick: @message.nick
      date: new Date
      text: text

    @_.messages ?= {}
    @_.messages[person] ?= []
    for message, index in @_.messages[person]
      if message.nick == @message.nick
        removed = yes
        @_.messages[person].splice index, 1
        break
    @_.messages[person].push message
    if removed
      "I've updated your message."
    else
      "Thanks. I will tell #{realCasePerson} about it."

exports._else = ->
  if @message.type is 'join'
    if @_.messages?[@message.nick.toLowerCase()]?
      for message in @_.messages[@message.nick.toLowerCase()]
        {nick, date, text} = message
        date = date.toUTCString()
        @respond "#{@message.nick}, #{nick} said \"#{text}\" to " +
                 "you on #{date}."
      delete @_.messages[@message.nick]
