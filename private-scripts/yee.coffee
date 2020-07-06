# Description:
#   None
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   yee - Summon the "yee" gif!
#
# Author:
#   Glossawy

module.exports = (robot) ->
  robot.hear /(^|\W)yee(\z|\W|$)/i, (msg) ->
    msg.send "http://media.giphy.com/media/vJcecZJ4oWKdO/giphy.gif"

