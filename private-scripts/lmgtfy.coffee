# Description:
#   You know goddamn well what this does
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   google <string> - provide a lmgtfy link for string
#
# Author:
#   Justin Tervay

module.exports = (robot) ->
	robot.hear /(.*)google (.*)/i, (res) ->
		message = res.match[0]
		checker = res.match[1]
		input = res.match[2]
		sender = res.message.user.name
		
		if (checker is "") and (input isnt "it")
			input2 = getUrl input
			res.send input2
			setTimeout () ->
				res.send "Was that so hard, #{sender}?"
			, 2500

`function getUrl(link) {
	return "http://lmgtfy.com/?q=" + encodeURIComponent(link);
}
`
