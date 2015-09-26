# Description:
#   Polling System for Cueball
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   cueball poll people about <topic> with options <choiceOne, choiceTwo, ..., choiceN>
#   cueball show voters for <id>
#   cueball vote in <id> for <option>
#   cueball end poll <id> [and archive as <name>]
#   cueball delete <name> from archive
#   cueball show active polls
#   cueball show options for <id>
#
# Author:
#   Matthew Crocco

module.exports = (robot) ->

    if not robot.brain.uuid_map?
        robot.brain.uuid_map = {}

    if not robot.brain.polls?
        robot.brain.polls = []

    robot.brain.uuid_map = {}

    filterMap = (map, predicate) ->
        result = {}

        for own key of map
            if predicate(key, map[key])
                result[key] = map[key]

        return result

    # I didn't wnant to make one myself, so algorithm credit:
    # https://gist.github.com/bmc/1893440
    #
    # Less characters used
    generateId = ->
        w = 'xyxxy'.replace(/[xy]/g, (c) ->
            r = Math.random() * 16 | 0
            v = if c is 'x' then r else (r & 0x3|0x8)
            v.toString(16)
        ).toUpperCase()

        if w of robot.brain.uuid_map
            return generateId()
        else
            return w

    getInstant = ->
        d = new Date()
        singleDigitRegex = /\b(\d)\b/g

        dateStamp = [(d.getMonth() + 1), d.getDate(), d.getFullYear()].join('/')
        timeStamp = [d.getHours(), d.getMinutes(), d.getSeconds()].join(' ')
        timeStamp = timeStamp.replace(singleDigitRegex, "0$1").replace /\s/g, ":"
        return timeStamp + " " + dateStamp

    registerPoll = (poll) ->
        for item in robot.brain.polls
            if item.getId() == poll.getId()
                throw new Error("Poll already registered with ID=#{item.getId()}!")

        robot.brain.polls.push poll
        robot.brain.uuid_map[poll.getId()] = poll

    removePoll = (poll) ->
        robot.brain.polls = robot.brain.polls.filter (t) -> t isnt poll
        robot.brain.uuid_map = filterMap(robot.brain.uuid_map, (id, v) -> id isnt poll.getId())

    class Poll
        constructor: (@host, @topic, @opts, @canChangeVote = false) ->
            @pollId = generateId()
            @creationTime = getInstant()
            @voters = {}
            @choices = (0 for i in [0..@opts.length])
            @voteCount = 0

        submitVote: (user, choice) ->
            if not isValidChoice(choice)
                throw new Error("#{choice} is not a valid option! use 'cueball show options for <id>'")

            if user of @voters
                if @canChangeVote
                    @choices[@voters[user]] = @choices[@voters[user]] - 1
                    @choices[choice] = @choices[choice] + 1
                    @voters[user] = choice
                else
                    throw new Error("Vote already submitted for #{user}! This poll does *_not_* allow changing votes")
            else
                @voters[user] = choice
                @voteCount = @voteCount + 1

        isValidChoice: (choice) -> 
            return choice in @opts or 
            typeof choice is 'number' and 
            choice >= 0 and 
            choice < @choices.length
        isVoteChangeable: -> return @canChangeVote
        getTopic: -> return @topic
        getChoices: -> return @opts
        getVotes: -> return @voteCount
        getId: -> return @pollId
        getCreationDate: -> return @creationTime
        getDescription: -> return "ID=#{@pollId} | '#{@topic}' with choices [#{@opts.toString()}] with #{@getVotes()} votes. Created By #{@host} on #{@creationTime}"
        getUseInfo: -> return "'#{@topic}' can be voted on using it's id (#{@pollId}) with choices between 1 and #{@opts.length}!"
        toString: -> return @getDescription()

    robot.respond /poll people about (".*?") with options ((.*?)+)/i, (msg) ->
        creator = msg.message.user.name
        topic = msg.match[1].trim()
        topic = topic.substring(1, topic.length-1)

        choices = msg.match[2].split(',').map (s) -> 
            s = s.trim()
            if s.charAt(0) == '\"' and s.charAt(s.length-1) == '\"'
                return s.substring(1, s.length-1)
            else
                return s

        newPoll = new Poll(creator, topic, choices)
        msg.reply "You're poll has been created! Details as follows:"
        msg.send "@channel: A new poll '#{newPoll.getTopic()}' has been created! With options #{newPoll.getChoices().join(', ')}"
        msg.send "Used the topic or id (#{newPoll.getId()}) and choices 1-#{choices.length} to vote!"
        msg.send "Example: cueball vote in #{newPoll.getId()} for #{Math.floor(Math.random() * (choices.length-1))}"

        registerPoll(newPoll)

    robot.respond /show options for (\w+)/i, (msg) ->
        id = msg.match[1].trim().toUpperCase()

        if id of robot.brain.uuid_map
            poll = robot.brain.uuid_map[id]
            msg.send poll.getChoices().join(', ')
            optStr = "[ #{poll.getChoices().map((val, i) -> "#{i}: #{val}").join(', ')} ]"
            msg.reply "Choices for #{poll.getTopic()} are #{optStr}"
            msg.send poll.getUseInfo()
        else
            msg.reply "The poll with id '#{id}' is not appearing in my database..."