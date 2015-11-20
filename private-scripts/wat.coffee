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
#   Jonathan Kleinfeld

module.exports = (robot) ->
  robot.hear /(^|\W)wat(\z|\W|$)/i, (msg) ->
    msg.send "http://i.imgur.com/lpBEIA5.png"
