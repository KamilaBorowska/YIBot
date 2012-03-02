exports._pastebin = (messages, channel, context) ->
  text = ''
  for message in messages
    [content, me, method] = message
    if me
      text += '/me '
    text += "#{content}\n"

  paste =
    public: no
    files:
      Text:
        content: text

  paste = JSON.stringify paste

  https = require 'https'
  options =
    host: 'api.github.com'
    path: '/gists'
    method: 'POST'
    headers:
      'content-length': Buffer.byteLength paste

  data = ''

  request = https.request options

  request.on 'response', (response) =>
    response.setEncoding 'utf8'
    response.on 'data', (chunk) =>
      data += chunk
    response.on 'end', =>
      @[context] JSON.parse(data).html_url, channel
      request.end()

  request.write paste
