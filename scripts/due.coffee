# Description:
#   Cueball can now remember due dates for people
# 
# Dependencies:
#   Moment js
# 
# Configuration:
#   None
# 
# Commands:
#   hubot due dates
# 
# Author:
#   Matthew Crocco

moment = require('moment')

module.exports = (robot) ->
	class Notification
		
		# Init Contains the Following:
		# Work [Required] - Name of Task
		# Delay [Required] - Length of Time Between reminders (must be > 0)
		# Unit [default: ms] - Time Unit (ms, s, d, w, m, y)
		# Repeat [default: false] - Should the reminder repeat
		constructor: (init) ->
			if not init?
				throw new ReferenceError('Init Object Not Provided!')
			else if not init.work?
				throw new ReferenceError('Init.Work Not Provided!')
			else if not init.delay?
				throw new ReferenceError('Init.Delay Not Provided!')
			else if init.delay <= 0
				throw new Error('Init.Delay must be > 0')

			@work = init.work
			@delay = init.delay
			@unit = init.unit or 'ms'
			@increment = moment.duration(@delay, @unit)
			@repeat = init.repeat or false
			@paused = false
			@next = null

		# The given callback is called with the task name periodically or once
		start: (cb) ->
			if @paused
				@paused = false
	
			@_next()
			setTimeout () =>
				if not @paused
					cb(@work)
					if @repeat
						@start(cb)
			, @next.diff(moment())

		stop: ->
			@paused = true

		_next: ->
			if not @next?
				@next = moment()

			rightNow = moment()
			while @next.isBefore(rightNow) or @next.isSame(rightNow)
				@next.add(@increment)


	_stdNotify = ->
    	(work) -> robot.send room:"compsci", "_REMEMBER: #{work} is due #{cueball_due.due_dates[work]}_"

    # Load and Put Back into Objects
	cueball_due = robot.brain.get("cueball_due") ? null
	if not cueball_due?
		cueball_due =
			due_dates : robot.brain.get( "due_dates") ? {},
			due_timers: robot.brain.get("due_timers") ? {}
		for own key, value of cueball_due.due_timers
			cueball_due.due_timers[value.work] = new Notification({work: value.work, delay: value.delay, unit: value.unit, repeat: value.repeat})
			cueball_due.due_timers[value.work].paused = value.paused
			cueball_due.due_timers[value.work].start(_stdNotify())
	else
		for own key, value of cueball_due.due_timers
			cueball_due.due_timers[value.work] = new Notification({work: value.work, delay: value.delay, unit: value.unit, repeat: value.repeat})
			cueball_due.due_timers[value.work].paused = value.paused
			cueball_due.due_timers[value.work].start(_stdNotify())

	filterMap = (map, predicate) ->
        result = {}

        for own key of map
            if predicate(key, map[key])
                result[key] = map[key]

        return result

	save = ->
		robot.brain.set('cueball_due', cueball_due)
		robot.brain.save()

	save()
	robot.respond /on (.*?) (".*?") is due/i, (msg) ->
		work = msg.match[2].trim()
		time = msg.match[1].trim()

		if work.length != 0 and time.length != 0
			cueball_due.due_dates[work] = time
			save()
			msg.send "_Work due date added!_"

	robot.respond /make (".*?") no longer due/i, (msg) ->
		work = msg.match[1].trim()

		if work.length != 0
			cueball_due.due_dates = filterMap(cueball_due.due_dates, (k, v) -> k isnt work)
			save()
			msg.send "_Work due date removed!_"

	robot.respond /due dates/i, (msg) ->
		response = "_Work due:_"

		for own key, value of cueball_due.due_dates
			response += "\n#{key} is due #{value}"

		msg.send response

	robot.respond /set reminder for (".*?") every ([1-9]\d*)(( ms| [sdmwy])|(ms|[sdmwy]))?/, (msg) ->
		work = msg.match[1]
		length = msg.match[2]
		unit = msg.match[3] or 'ms'

		if cueball_due.due_dates[work]?
			cueball_due.due_timers[work] = new Notification({work: work, delay: parseInt(length, 10), unit: unit, repeat: true})
			cueball_due.due_timers[work].start(_stdNotify())
			save()
			msg.send "_Reminder Added to #{work}!_"
		else
			msg.send "_#{work} does not exist!_"

	robot.respond /clear reminder for (".*?")/i, (msg) ->
		work = msg.match[1]

		if cueball_due.due_dates[work]? and cueball_due.due_timers[work]?
			cueball_due.due_timers[work].stop()
			delete cueball_due.due_timers[work]
			save()
			msg.send "_Reminder Removed for #{work}!_"
		else
			msg.send "_#{work} does not exist or it does not have a timer..._"
