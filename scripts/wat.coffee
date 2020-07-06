# Description :
#   None
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   wat - Summons Wat Lady
#
# Author:
#   Jonathan Kleinfeld and Glossawy

options = [
  "http://i.imgur.com/7kZ562z.jpg",
  "http://i.imgur.com/lpBEIA5.png",
  "http://i.imgur.com/fd7GJoA.jpg",
  "http://i.imgur.com/KeiQSS5.jpg",
  "http://i.imgur.com/LTj5W8x.jpg"
]

module.exports = (robot) ->

  robot.listen(
    (message) ->
      message.text? and message.text is 'wat'
    (resp) ->
      resp.send resp.random options
  )
