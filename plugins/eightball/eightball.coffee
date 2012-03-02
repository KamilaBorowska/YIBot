exports['8ball'] = exports.eightball = ->
  responses = [
    # strongly affirmative
    'It is certain'
    'It is decidedly so'
    'Without a doubt'
    'Yes – definitely'
    'You may rely on it'
    # tentatively affirmative
    'As I see it, yes'
    'Most likely'
    'Outlook good'
    'Signs point to yes'
    'Yes'
    # non-committal
    'Reply hazy, try again'
    'Ask again later'
    'Better not tell you now'
    'Cannot predict now'
    'Concentrate and ask again'
    # negative
    "Don't count on it"
    'My reply is no'
    'My sources say no'
    'Outlook not so good'
    'Very doubtful'
  ]
  @respond responses[Math.floor(Math.random() * responses.length)]