# Static variables
ops =
  Functions: [
    Name: '-'
    Callback: (a) -> -a
    Precedence: 10
    Right: yes
  ,
    Name: '+'
    Callback: (a) -> +a
    Precedence: 10
    Right: yes
  ,
    Name: '~'
    Callback: (a) -> ~a
    Precedence: 10
    Right: yes
  ,
    Name: '!'
    Callback: (a) -> !a
    Precedence: 10
    Right: yes
  ]
  Operators: [
    Name: '||'
    Callback: (a, b) -> a or b
    Precedence: 1
  ,
    Name: '&&'
    Callback: (a, b) -> a and b
    Precedence: 2
  ,
    Name: '|'
    Callback: (a, b) -> a | b
    Precedence: 3
  ,
    Name: '^'
    Callback: (a, b) -> a ^ b
    Precedence: 3
  ,
    Name: '&'
    Callback: (a, b) -> a & b
    Precedence: 4
  ,
    Name: '==='
    Callback: (a, b) -> a is b
    Precedence: 5
  ,
    Name: '=='
    Callback: (a, b) -> a is b
    Precedence: 5
  ,
    Name: '!=='
    Callback: (a, b) -> a isnt b
    Precedence: 5
  ,
    Name: '!='
    Callback: (a, b) -> a isnt b
    Precedence: 5
  ,
    Name: '<='
    Callback: (a, b) -> a <= b
    Precedence: 6
  ,
    Name: '<<'
    Callback: (a, b) -> a << b
    Precedence: 7
  ,
    Name: '<'
    Callback: (a, b) -> a < b
    Precedence: 6
  ,
    Name: '>='
    Callback: (a, b) -> a >= b
    Precedence: 6
  ,
    Name: '>>>'
    Callback: (a, b) -> a >>> b
    Precedence: 7
  ,
    Name: '>>'
    Callback: (a, b) -> a >> b
    Precedence: 7
  ,
    Name: '>'
    Callback: (a, b) -> a > b
    Precedence: 6
  ,
    Name: '+'
    Callback: (a, b) -> a + b
    Precedence: 8
  ,
    Name: '-'
    Callback: (a, b) -> a - b
    Precedence: 8
  ,
    Name: '**'
    Callback: (a, b) -> Math.pow a, b
    Precedence: 11
    Right: yes
  ,
    Name: '*'
    Callback: (a, b) -> a * b
    Precedence: 9
  ,
    Name: '/'
    Callback: (a, b) ->
      if b is 0
        throw new Error 'Chuck Norris can divide by zero, but I cannot.'
      else
        a / b
    Precedence: 9
  ,
    Name: '%'
    Callback: (a, b) ->
      if b is 0
        throw new Error 'Chuck Norris can do modulo by zero, but I cannot.'
      else
        Math.abs(a) % Math.abs(b)
    Precedence: 9
  ]

exports.math = exports.calc = ->
  value = try
    value = postfix infix @message.value
    if value is true
      'true'
    else if value is false
      'false'
    else
      value
  catch exception
    "Fail: #{exception.message}"

  @respond value

exports.rpn = ->
  expression = infix @message.value

  string = ''
  for value, i in expression
    if i isnt 0
      string += ' '
    if value.Name?
      string += value.Name
    else
      string += value

  @respond string

infix = (expr) ->
  # Regexp for EcmaScript numbers
  number = ///
    ^              # Beginning of the string
    (?:
      0x[0-9a-f]   # Hexadecimal numbers
    |
      (?:
        \d*        # Any number of digits
        [.]?       # Optional dot
        \d+        # At least one digit
      |
        \d+        # Specific case of nothing after dot
        [.]
      )
      (?:          # Optional scientific notation
        e
        [+\-]?     # Optional sign before number
        \d+        # Digit itself
      )?
    )
  ///

  stack = []
  output = []
  expr = "#{expr}".toLowerCase()
  expectsOp = no

  while expr isnt ''
    append = 1
    group = if expectsOp then 'Operators' else 'Functions'
    float = number.exec(expr)?[0]
    if float
      output.push +float
      expectsOp = yes
      append = float.length
    else if expr.substr(0, 1) is '('
      stack.unshift '('
    else if expr.substr(0, 1) is ')'
      do ->
        for operator, i in stack
          continue if operator is undefined
          delete stack[i]
          return if operator is '('
          output.push operator

        throw new Error 'Mismatched parenthesis.'
    else if expr.substr(0, 1) isnt ' '
      operator = do ->
        for operator in ops[group]
          if expr.substr(0, operator.Name.length) is operator.Name
            expectsOp = no
            append = operator.Name
            return operator
        throw new Error 'Excepting operator, got something unknown.'
      operator.Arguments = if group is 'Operators' then 2 else 1
      for value, i in stack
        break if value is '('
        continue if value is undefined
        if not operator.Right and operator.Precedence <= value.Precedence
          output.push value
          delete stack[i]
        else if operator.Right and operator.Precence < value.Precedence
          output.push value
          delete stack[i]
        else
          break
      stack.unshift operator
      append = operator.Name.length
    expr = expr.substr append

  for operator in stack
    throw new Error 'Mismatched parenthesis.' if operator is '('
    continue if operator is undefined
    output.push operator

  output

postfix = (expression) ->
  stack = []
  for value in expression
    if value.Callback?
      throw new Error 'Stack error?' if value.Arguments > stack.length
      arguments = []
      for [1 .. value.Arguments]
        arguments.push stack.pop()
      stack.push value.Callback arguments.reverse()...
    else
      stack.push value
  if stack.length is 1
    stack[0]
  else
    throw new Error 'Wrong stack length?'
