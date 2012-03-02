# YIBot 2.0

console.log '''
  WARNING: This is technical preview. Any API may change without warning!
'''

# Merge objects function
objectJoin = (objects...) ->
  finalObject = {}
  for object in objects
    for property, value of object
      finalObject[property] = value

  # Return finished object when completed.
  finalObject

# Load configuration file
{config, globals} = require './config'
global.servers = {}

for name, server of config
  # If type is recognized, join with globals
  if globals?[server.Type]?
    server = objectJoin globals[server.Type], server

  # Load server information and initalize server.
  socket = require("./servers/#{server.Type}")[server.Type]

  # Start connection and after having control again start next iteration
  (global.servers[name] = new socket name, server).connect()

# Yes, it's whole code. Seriously.