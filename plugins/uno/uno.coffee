# Underscore.js 1.3.1
# (c) 2009-2012 Jeremy Ashkenas, DocumentCloud Inc.
# Underscore is freely distributable under the MIT license.
# Portions of Underscore are inspired or borrowed from Prototype,
# Oliver Steele's Functional, and John Resig's Micro-Templating.
# For all details and documentation:
# http://documentcloud.github.com/underscore
shuffle = (obj) ->
  shuffled = []
  for value, index in obj
    if index is 0
      shuffled[0] = value
    else
      rand = Math.floor Math.random() * (index + 1)
      [shuffled[index], shuffled[rand]] = [shuffled[rand], value]
  shuffled

# Now for actual code. Look, I haven't included Underscore. I don't want to
# make dependency hell.


class unoPlay
  constructor: (@this) ->
    # Settings
    @channel = undefined
    # Various stuff
    @running = no
    # Deck
    @deck = @getDeck()
    # Current players
    @players = []
    # Players data
    @data = {}
    # During joining
    @joining = no
    # Top card
    while not /\d$/.test(@topCard)
      @topCard = @pop()
    # Is color choosed
    @isColorChoosed = no
    # Was card drew
    @wasCardDrew = no
    # Was the bot forced
    @forceBot = no
    # Number of timeouts
    @timeouts = 0
    # Timeout
    @timeout = no
    
  getDeck: ->
    shuffle '''
      B0 B1 B1 B2 B2 B3 B3 B4 B4 B5 B5 B6 B6 B7 B7 B8 B8 B9 B9 BR BR BS BS BD
      BD R0 R1 R1 R2 R2 R3 R3 R4 R4 R5 R5 R6 R6 R7 R7 R8 R8 R9 R9 RR RR RS RS
      RD RD Y0 Y1 Y1 Y2 Y2 Y3 Y3 Y4 Y4 Y5 Y5 Y6 Y6 Y7 Y7 Y8 Y8 Y9 Y9 YR YR YS
      YS YD YD G0 G1 G1 G2 G2 G3 G3 G4 G4 G5 G5 G6 G6 G7 G7 G8 G8 G9 G9 GR GR
      GS GS GD GD WD WD WD WD W W W W
    '''.split /\s/

  endJoining: =>
    notice = @this.notice or @this.pm
    @joining = no
    if @players.length is 1 and not @forceBot
      @forceBot = yes
      # Push YIBot to gameplay if there is just one player
      @players.push @this.currentNick
    if @players.length >= 1
      @players = shuffle @players
      @running = yes
      for player in @players
        @data[player] = {}
        @data[player].cards = []
        for [1..7]
          @data[player].cards.push @pop()
        if player isnt @this.currentNick
          notice 'Your cards: ' + (for card in @data[player].cards
              @expand card, yes).sort().join(' | '), player
      players = @players.join ', '
      @this.send "So, let's start! Player order: #{players}", @channel

      card = @expand @topCard
      @this.send "By the way, I have set #{card} as top card.", @channel
      @running = yes
      @setTimeout()

      # Let's start with AI if this happens...
      if @players[0] is @this.currentNick
        @ai()
    else
      @this.send 'I will stop because nobody is interested.', @channel

  pop: =>
    if @deck is []
      @deck = @getDeck()
    @deck.pop()

  expand: (name, bold) ->
    bold = if bold and @doesFit name then "\x02" else ""
    bold + name.replace(/^B$/, '\x0312Wild (Blue)')
               .replace(/^R$/, '\x035Wild (Red)')
               .replace(/^G$/, '\x039Wild (Green)')
               .replace(/^Y$/, '\x038Wild (Yellow)')
               .replace(/WD/, 'Wild Draw Four')
               .replace(/^B/, '\x0312Blue ')
               .replace(/^R/, '\x035Red ')
               .replace(/^G/, '\x039Green ')
               .replace(/^Y/, '\x038Yellow ')
               .replace(/R$/, 'Reverse')
               .replace(/S$/, 'Skip')
               .replace(/D$/, 'Draw Two')
               .replace(/^W$/, 'Wild') + "\x0F"

  simplify: (name) ->
    if result = /^([RGBYW])(?:(?:.*?\s+.*?\b)?([SRD0-9]|$)|\w+)/i.exec name
      result[1..2].join('').toUpperCase()

  nextPlayer: (skipped = no) =>
    notice = @this.notice or @this.pm
    @wasCardDrew = no
    @isColorChoosed = no

    @players.push @players.shift()
    if skipped
      @timeouts = 0
      @this.send "#{@players[0]}'s round was skipped!", @channel
    else
      if not @running
        clearTimeout @timeout if @timeout
        @this.send "#{@this.message.nick} has WON!", @channel
        for nick in @players
          if @data[nick].cards.length is 0
            @this.send "#{nick}: NONE!", @channel
          else
            @this.send "#{nick}: " + (for card in @data[nick].cards
              @expand card).sort().join(' | '), @channel
      else
        @setTimeout()
        message = "Continuing with #{@players[0]}'s round! " +
                  "The top card is #{@expand @topCard}."
        if @players[0] is @this.currentNick
          # Time for some sort of AI...
          @ai()
        else
          @this.send message, @channel
          notice 'Your cards: ' + (for card in @data[@players[0]].cards
            @expand card, yes).sort().join(' | '), @players[0]

  setTimeout: ->
    clearTimeout @timeout if @timeout
    @timeout = setTimeout (=>
      timeouts = @timeouts + 1
      if timeouts == @players.length - @forceBot
        @running = no
        @this.send (if @players.length == 2
          'Sorry, but game was stopped because of inactivity'
        else
          'Stopping game because too many timeouts.'), @channel
      else
        @ignorePlayer = yes
        @this._ =
          uno: this
        @this.send "Too late, #{@players[0]}.", @channel
        if @isColorChoosed
          exports.color.call @this, undefined, color
        else
          unless @wasCardDrew
            exports.draw.call @this
          exports.pass.call @this
        @timeouts = timeouts
        @ignorePlayer = no
    ), 150000
    
  doesFit: (card) =>
    card[0] is @topCard[0] or card[1] is @topCard[1] or card[0] is 'W'

  # The UNO AI
  ai: =>
    @this.message ?= {}
    @this.message.channel = @channel
    @this.message.nick = @this.currentNick

    max = (object)->
      [maxName, maxValue] = ['W', 0]
      for own name, value of object
        continue if name[0] is 'W'
        if value >= maxValue
          [maxName, maxValue] = [name, value]
      maxName

    # Please note that it isn't cheating as it only looks at number of cards.
    enemyCards = @data[@players[1]].cards.length

    [currentColor, currentNumber] = @topCard
    colors = {}
    numbers = {}

    myCards = @data[@players[0]].cards
    for card in myCards
      [color, number] = card
      colors[color] ?= 0
      numbers[number] ?= 0
      colors[color]++
      numbers[number]++

    if enemyCards <= 3
      toTry = ['WD', 'RD', 'BD', 'GD', 'YD', 'RS', 'BS', 'GS', 'YS',
               'W',  'RR', 'BR', 'GR', 'YR']

      # Filter out ONLY usable cards from this list
      toTry = (card for card in toTry when card in myCards and @doesFit card)

      if toTry.length > 0
        @this.message.value = toTry[0]
        exports.play.apply @this
        if @isColorChoosed
          @this.message.value = max colors
          if @this.message.value is 'W'
            # Because I seriously don't care about colors
            @this.message.value = 'G'
          exports.color.apply @this
        return
    # If we are there, then situation isn't critical or there is no fitting
    # card. If this is the case, try to choose any good card...
    myCards = (card for card in myCards when @doesFit card)

    if myCards.length is 0
      # Try drawing cards
      exports.draw.apply @this
      myCards = @data[@players[0]].cards
      myCards = (card for card in myCards when @doesFit card)
      # Still no fitting cards? Give up!
      if myCards.length is 0
        exports.pass.apply @this
        return

    results = {}
    for card in myCards
      [color, number] = card
      results[card] = 0
      if colors[color]?
        results[card] += colors[color]
      if numbers[number]?
        results[card] += numbers[number]

    @this.message.value = max results

    if @this.message.value is 'W'
      if 'W' not in myCards
        @this.message.value = 'WD'
    
    exports.play.apply @this

    if @isColorChoosed
      @this.message.value = max colors
      if @this.message.value is 'W'
        # Because I seriously don't care about colors
        @this.message.value = 'R'
      exports.color.apply @this

respond = (uno, msg) ->
  @send msg, uno?.channel or @message.channel
      
exports.uno = ->
  respond.call this, uno, if @_.uno?.running or @_.uno?.joining
    'Sorry, but UNO is already running!'
  else
    @_.uno = uno = new unoPlay this
    uno.channel = @message.channel
    uno.joining = yes
    @_.timeout = setTimeout uno.endJoining, 60 * 1000
    'You have 60 seconds to start. Use "join" command to join.'

exports.unostart = ->
  return if (uno = @_.uno)?.running
  uno = @_.uno
  if @_.timeout?
    clearTimeout @_.timeout
    delete @_.timeout
    uno.endJoining()

exports.j = exports.jo = exports.join = ->
  return if (uno = @_.uno)?.running
  if @message.nick in uno.players
    respond.call this, uno, 'Sorry, but you\'re already playing.'
  else
    uno.players.push @message.nick
    respond.call this, uno, 'I have added you. Does anybody else want to play?'

exports.invite = ->
  uno = @_.uno
  if uno?
    respond.call this, uno, if uno.running
      "Sorry, but I think it's already running. Perhaps next time."
    else if uno.forceBot
      'I have already said that I will take the part in this game!'
    else
      uno.forceBot = true
      uno.players.push @currentNick
      'Sure. I will take the part in this game :).'

exports.cards = exports.ca = ->
  notice = @notice or @pm
  return unless (uno = @_.uno)?.running
  notice (for card in uno.data[@message.nick].cards
           uno.expand card, yes).sort().join(' | '), @message.nick

exports.play = exports.pl = exports.p = ->
  notice = @notice or @pm
  return unless (uno = @_.uno)?.running
  if uno.players[0] isnt @message.nick and not uno.ignorePlayer
    respond.call this, uno, "Please wait. Currently, we have #{uno.players[0]}'s round!"
    return
  if uno.isColorChoosed
    respond.call this, uno, 'Choose a color using "co" command! Seriously!'
    return
  # Wild Draw Four is actually WD
  card = uno.simplify @message.value
  # This long line checks if card is playable
  if not card?
    respond.call this, uno, "Sorry, but I couldn't understand your request."
  else if uno.doesFit card
    if @message.nick is @currentNick
      respond.call this, uno, "#{@currentNick} is placing #{uno.expand card}."
    index = uno.data[uno.players[0]].cards.indexOf card
    if index >= 0
      if uno.data[uno.players[0]].cards.length is 2
        respond.call this, uno, "#{uno.players[0]} says UNO!"
      else if uno.data[uno.players[0]].cards.length is 1
        uno.running = no

      uno.data[uno.players[0]].cards.splice index, 1
      uno.topCard = card

      switch card[1]
        # Wild card
        when undefined
          uno.isColorChoosed = yes
          if uno.running and @currentNick isnt @message.nick
            respond.call this, uno, 'Choose a color using "co" command!'
          return
        when 'D'
          # Wild draw four
          if card[0] is 'W'
            uno.isColorChoosed = yes

            cards = []
            for [1..4]
              cards.push uno.pop()

            receive = for card in cards
              uno.data[uno.players[1]].cards.push card
              uno.expand card

            target = uno.players[1]

            if target isnt @currentNick
              notice "You have received #{receive.join(', ')}. Very fun!", target

            respond.call this, uno, "#{target} has received four cards!"

            if uno.running
              if @currentNick isnt @message.nick
                respond.call this, uno, 'Choose a color using "co" command!'
              return
            else
              uno.nextPlayer yes
          # Draw two
          else
            cards = []
            for [1..2]
              cards.push uno.pop()

            receive = for card in cards
              uno.data[uno.players[1]].cards.push card
              uno.expand card, yes

            target = uno.players[1]
            if target isnt @currentNick
              notice "You have received #{receive.join(' and ')}. Fun!", target
            respond.call this, uno, "#{target} has received two cards!"

            uno.nextPlayer yes
        when 'R'
          if uno.players.length == 2
            uno.nextPlayer yes
          else
            respond.call this, uno, 'Order was reversed!'
            uno.players[1..] = uno.players[1..].reverse()
        when 'S'
          uno.nextPlayer yes
      uno.timeouts = 0
      uno.nextPlayer no
    else
      respond.call this, uno, 'You don\'t have this card.'
  else
    respond.call this, uno, "Sorry, but this card isn't playable now."

exports.card = exports.cd = ->
  return unless (uno = @_.uno)?.running
  respond.call this, uno, "Currently played: #{uno.expand uno.topCard}"

exports.draw = exports.dr = exports.d = ->
  notice = @notice or @pm
  return unless (uno = @_.uno)?.running
  if uno.players[0] isnt @message.nick and not uno.ignorePlayer
    respond.call this, uno, "Please wait. Currently, we have #{uno.players[0]}'s round!"
  else if uno.wasCardDrew
    respond.call this, uno, 'Sorry, but you have drew card already.'
  else
    card = uno.pop()
    uno.data[uno.players[0]].cards.push card
    respond.call this, uno, "#{uno.players[0]} has drew the card."
    if @message.nick isnt @currentNick or uno.ignorePlayer
      notice "Spoiler: This card is #{uno.expand card, yes}.", uno.players[0]
    uno.wasCardDrew = yes

exports.pa = exports.pass = ->
  return unless (uno = @_.uno)?.running
  if uno.players[0] isnt @message.nick and not uno.ignorePlayer
    respond.call this, uno, "Please wait. Currently, we have #{uno.players[0]}'s round!"
  else if uno.wasCardDrew and not uno.isColorChoosed
    uno.timeouts = 0
    respond.call this, uno, "#{uno.players[0]} has skipped his round!"
    uno.nextPlayer no
  else if uno.isColorChoosed
    respond.call this, uno, "Choose color, seriously!"
  else
    respond.call this, uno, 'Have you drew the card?'

exports.stats = exports.stat = exports.st = exports.s = exports.count = exports.ct = ->
  return unless (uno = @_.uno)?.running
  for player in uno.players
    respond.call this, uno, "#{player}: #{uno.data[player].cards.length}"
    
exports.co = exports.c = exports.color = (blah, color) ->
  return unless (uno = @_.uno)?.running
  if uno.players[0] isnt @message.nick
    respond.call this, uno, "Please wait. Currently, we have #{uno.players[0]}'s round!"
    return
  if uno.isColorChoosed
    color or= @message.value
    color = color.toUpperCase()[0]
    if /[RGBY]/.test(color)
      if uno.topCard is 'WD'
        uno.nextPlayer yes
      uno.topCard = "#{color}(Wild)"
      uno.timeouts = 0
      uno.nextPlayer no
    else
      respond.call this, uno, 'Unknown color'
  else
    respond.call this, uno, 'You should first use Wild Card, you know...'
