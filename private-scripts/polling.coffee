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
#   hubot poll people about <topic> with options <choiceOne, ..., choiceN>
#   hubot vote in <id> for <option>
#   hubot view <id>
#   hubot view <name> from archive
#   hubot show options for <id>
#   hubot show voters for <id>
#   hubot what did I vote for in <id>?
#   hubot show active polls
#   hubot end poll <id> [and archive as <name>]
#   hubot delete <name> from archive
#   hubot polling help
#
# Author:
#   Glossawy

module.exports = (robot) ->

  polling_commands = [
      "#{robot.name} poll people about <topic> with options <choiceOne, " +
      "choiceTwo, ..., choiceN>",
      "#{robot.name} vote in <id> for <option>",
      "#{robot.name} view <id>",
      "#{robot.name} view <name> from archive",
      "#{robot.name} show options for <id>",
      "#{robot.name} show voters for <id>",
      "#{robot.name} what did I vote for in <id>?",
      "#{robot.name} show active polls",
      "#{robot.name} end poll <id> [and archive as <name>]",
      "#{robot.name} delete <name> from archive",
      "#{robot.name} polling help"
  ]

  if not robot.brain.uuid_map?
    robot.brain.uuid_map = {}

  if not robot.brain.polls?
    robot.brain.polls = []

  if not robot.brain.archives?
    robot.brain.archives = {}

  _saveBrain = -> robot.brain.save()

  isIdExists = (uuid) -> return uuid of robot.brain.uuid_map

  lengthMap = (map) ->
    size = 0
    for own k of map
      size++
    return size

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

  retrievePoll = (id) ->
    if isIdExists id
      return robot.brain.uuid_map[id]
    else
      return null

  registerPoll = (poll) ->
    for item in robot.brain.polls
      if item.getId() == poll.getId()
        throw new Error("Poll already registered with ID=#{item.getId()}!")

    robot.brain.polls.push poll
    robot.brain.uuid_map[poll.getId()] = poll
    _saveBrain()

  removePoll = (poll, archiveName = null) ->
    robot.brain.polls = robot.brain.polls.filter (t) -> t isnt poll
    robot.brain.uuid_map = filterMap(robot.brain.uuid_map, (id, v) ->
      id isnt poll.getId())

    if archiveName?
      robot.brain.archives[archiveName] = poll

    _saveBrain()

  isArchived = (archiveName) -> return archiveName of robot.brain.archives

  removeArchivedPoll = (archiveName) ->
    robot.brain.archives = filterMap(robot.brain.archives, (name, v) ->
      name isnt archiveName)
    _saveBrain()

  retrieveArchivedPoll = (archiveName) ->
    if archiveName of robot.brain.archives
      return robot.brain.archives[archiveName]
    else
      return null

  isSuperAdmin = (user) ->
    return user in process.env.HUBOT_POLLING_SUPERS.split(':')

  class Poll
    constructor: (@host, @topic, @opts, @canChangeVote = true) ->
      @pollId = generateId()
      @creationTime = getInstant()
      @voters = {}
      @choices = (0 for i in [0..@opts.length])
      @voteCount = 0

    submitVote: (user, choice) ->
      if not @isValidChoice(choice)
        throw new Error("#{choice} is not a valid option! " +
          "use 'cueball show options for <id>'")

      if user of @voters
        if @canChangeVote
          @choices[@voters[user]] = @choices[@voters[user]] - 1
          @choices[choice] = @choices[choice] + 1
          @voters[user] = choice
        else
          throw new Error("Vote already submitted for #{user}! This poll does"+
          " *_not_* allow changing votes")
      else
        @voters[user] = choice
        @choices[choice] = @choices[choice] + 1
        @voteCount = @voteCount + 1

    isValidChoice: (choice) ->
      return choice in @opts or
      typeof choice is 'number' and
      choice >= 0 and
      choice < @choices.length
    isVoteChangeable: -> return @canChangeVote

    getChoiceIndexOf: (user) ->
      return if user of @voters then @voters[user] else -1
    getChoiceOf: (user) ->
      idx = @getChoiceIndexOf(user)
      return if idx < 1 then null else @opts[idx-1]
    getVoters: -> return @voters
    getVotesFor: (idx) -> return @choices[idx]
    getVotesForName: (name) ->
      if name in @opts
        return @getVotesFor(@opts.indexOf(name)+1)
      else
        return -1
    getTopic: -> return @topic
    getChoices: -> return @opts.slice()
    getVotes: -> return @voteCount
    getId: -> return @pollId
    getCreationDate: -> return @creationTime
    getCreator: -> return @creator
    getDescription: ->
      return "ID=#{@pollId} | '#{@topic}' with choices [#{@opts.toString()}]"+
      " with #{@getVotes()} votes. Created By #{@host} on #{@creationTime}"
    getUseInfo: -> return "'#{@topic}' can be voted on using it's id "+
      "(#{@pollId}) with choices between 1 and #{@opts.length}!"
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
    msg.reply "Your poll has been created! Details as follows:\n" +
    "Use the id (#{newPoll.getId()}) and choices 1-#{choices.length} to vote!" +
    "\nExample: cueball vote in #{newPoll.getId()} for " +
    "#{Math.floor(Math.random() * (choices.length-1)) + 1}"

    registerPoll(newPoll)

  robot.respond /vote in (\w+) for ((.*?)+)/i, (msg) ->
    user = msg.message.user.name
    id = msg.match[1].trim().toUpperCase()
    decisionStr = msg.match[2].trim()
    decision = parseInt(decisionStr, 10)

    poll = retrievePoll(id)

    if poll?
      poll = robot.brain.uuid_map[id]

      try
        poll.submitVote(user, decision)
        msg.reply "You have uccessfully voted for"+
        " '#{poll.getChoices()[decision-1]}' in the poll, '#{poll.getTopic()}'!"
      catch error
        msg.reply "Something went wrong! - #{error.message}"
    else
      msg.reply "The poll with id '#{id}' is not appearing in my database..."

  robot.respond /show options for (\w+)/i, (msg) ->
    id = msg.match[1].trim().toUpperCase()

    poll = retrievePoll(id)

    if poll?
      pollStr = poll.getChoices().map((val,i) -> "#{i+1}: #{val}").join(', ')
      msg.reply "Choices for #{poll.getTopic()} are [ #{pollStr} ]"
      msg.send poll.getUseInfo()
    else
      msg.reply "The poll with id '#{id}' is not available..."

  robot.respond /show voters for (\w+)/i, (msg) ->
    id = msg.match[1].trim().toUpperCase()

    poll = retrievePoll(id)

    if poll?
      voters = poll.getVoters()
      voteTotal = poll.getVotes()
      resp = null

      if voteTotal == 1
        resp = "1 person has voted:"
      else
        resp = "\n#{voteTotal} people have voted:"

      for own k of voters
        resp = resp + "\n#{k}"

      msg.send resp
    else
      msg.reply "The poll with id '#{id}' is not appearing in my database..."

  robot.respond /what did I vote for in (\w+)/i, (msg) ->
    user = msg.message.user.name
    id = msg.match[1].trim().toUpperCase()

    poll = retrievePoll(id)

    if poll?
      choiceIdx = poll.getChoiceIndexOf(user)
      choice = poll.getChoices()[choiceIdx-1]
      if choice?
        msg.reply "You voted for option #{choiceIdx}, '#{choice}', in "+
        "the poll titled '#{poll.getTopic()}'"

        if poll.isVoteChangeable()
          msg.send 'This vote can be changed.'
        else
          msg.send 'This vote can\'t be changed!'

      else
        msg.reply "You have not yet voted in '#{poll.getTopic()}'! Do so"+
        " using it's ID! Which is '#{poll.getId()}'"
    else
      msg.reply "The poll with id '#{id}' is not appearing in my database..."

  robot.respond /show active polls/i, (msg) ->
    len = lengthMap(robot.brain.uuid_map)
    stmt = if len == 1 then "is 1 poll" else "are #{len} polls"
    resp = "There #{stmt} available:\n"

    for own id, poll of robot.brain.uuid_map
      resp += "#{id}: "+
      "#{if poll.getVotes() == 1 then "1 vote" else poll.getVotes() +" votes"}"+
      "\t'#{poll.getTopic()}'\n"

    msg.reply resp

  robot.respond /(end poll (\w+))( and archive as ((".*?")|('.*?')))?/i,(msg) ->
    id = msg.match[2].trim().toUpperCase()
    archiveName = msg.match[4]?.trim()
    poll = retrievePoll(id)

    user = msg.message.user.name

    if !archiveName? and msg.match[0].trim().length != 14
      msg.reply "If you are trying to archive please make sure to say 'and "+
      "archive as \"<name here>\"'!\nSince your request is not proper, the "+
      "poll will not be deleted as a precaution."
      return

    if archiveName?
      archiveName = archiveName.substring(1, archiveName.length-1)

    if poll?
      if isArchived(archiveName)
        msg.reply "Cannot archive using the name '#{archiveName}'! It is taken!"
      else
        if isSuperAdmin(user) or poll.getCreator() is user
          removePoll(poll, archiveName)
          msg.reply "The poll, '#{poll.getTopic()}' has been removed."
          if archiveName?
            msg.send "Archived as '#{archiveName}'"
        else
          msg.reply "#{user} you are not the poll creator "+
          "(#{poll.getCreator()}) nor are you an admin!"
    else
      msg.reply "The poll with id '#{id}' is not appearing in my database..."

  robot.respond /delete ((".*?")|('.*?')) from archive/i, (msg) ->
    user = msg.message.user.name
    archiveName = msg.match[1].trim()
    archiveName = archiveName.substring(1, archiveName.length-1)

    poll = retrieveArchivedPoll(archiveName)

    if poll?
      if isSuperAdmin(user) or poll.getCreator() is user
        removeArchivedPoll(archiveName)
        msg.reply "The poll, '#{poll.getTopic()}', has been totally deleted!"
      else
        msg.reply "#{user} you are not the poll creator (#{poll.getCreator()})"+
        " nor are you an admin!"
    else
      msg.reply "The archived poll with name '#{archiveName}' is not "+
      "appearing in my database..."

  robot.respond /view ((("|').*?("|'))( from archive)|(\w+))/i, (msg) ->
    fromArchive = msg.match[5].trim() is 'from archive'
    identifier = msg.match[2].trim()

    if fromArchive
      identifier = identifier.toUpperCase()

    poll = null

    if fromArchive
      identifier = identifier.substring(1, identifier.length-1)

      poll = retrieveArchivedPoll(identifier)
      if !poll?
        msg.reply "The archived poll with name '#{identifier}' is not "+
        "appearing in my database..."
        return
    else
      poll = retrievePoll(identifier)
      if !poll?
        msg.reply "The poll with id '#{identifier}' is not available..."
        return

    resp = 'Review is as follows,'
    poll.getChoices()
    .map((v, i) ->
      return [i+1, v]
    ).sort((a,b) ->
      return poll.getVotesForName(b[1]) - poll.getVotesForName(a[1])
    ).forEach (v) ->
      resp += "\nChoice \##{v[0]}: '#{v[1]}' with #{poll.getVotesFor(v[0])}"

    msg.reply resp

  robot.respond /polling help/i, (msg) ->
    resp = ""
    for cmd in polling_commands
      resp += "#{cmd}\n"

    msg.send resp.substring(0, resp.length-1)
