# Description:
#   Cueball can now remember due dates for people
# 
# Dependencies:
#   None
# 
# Configuration:
#   None
# 
# Commands:
#   hubot due dates
# 
# Author:
#   Matthew Crocco

module.exports = (robot) ->
	filterMap = (map, predicate) ->
        result = {}

        for own key of map
            if predicate(key, map[key])
                result[key] = map[key]

        return result

    due_dates = robot.brain.get("due_dates") ? {}

	save = ->
		robot.brain.set("due_dates", due_dates)
		robot.brain.save()

	robot.respond /on (.*?) (".*?") is due/, (msg) ->
		work = msg.match[2].trim()
		time = msg.match[1].trim()

		if work.length != 0 and time.length != 0
			due_dates[work] = time
			save()
			msg.send "_Work due date added!_"

	robot.respond /make (".*?") no longer due/, (msg) ->
		work = msg.match[1].trim()

		if work.length != 0
			due_dates = filterMap(due_dates, (k, v) -> k isnt work)
			save()
			msg.send "_Work due date removed!_"

	robot.respond /due dates/i, (msg) ->
		response = "_Work due:_"

		for own key, value of due_dates
			response += "\n#{key} is due #{value}"

		msg.send response