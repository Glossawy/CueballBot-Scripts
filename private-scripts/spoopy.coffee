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
#   spoopy - Summons spoopy skeleton gif
#
# Author:
#  Matt Gibson

module.exports = (robot) ->
  robot.hear /(^|\W)spoopy(\z|\W|$)/i, (msg) ->
    msg.send "https://media.giphy.com/media/xTiTnGUbQS1FqGl2iA/giphy.gif"
