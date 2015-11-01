# Description:
#   A Google Link and LMGTFY Link generator for the sarcastic
# 
# Dependencies:
#   None
# 
# Configuration:
#   None
# 
# Commands:
#   hubot google <query> - Cueball provides the search link and a witty response!
#   (@user) google <query> - provide a lmgtfy link for string
# 
# Author:
#   Justin Tervay and Matthew Crocco
#
# Last Edit: Matthew Crocco - Clean up, move to CoffeeScript only, separate Google and LMGTFY, refine Regex

module.exports = (robot) ->

  getUrl = (link) ->
    return "https://google.com/search?btnG=1&pws=1&gws_rd=ssl&newwindow=1&q=#{encodeURIComponent(link)}"

  getLmgtfy = (link) ->
    return "http://lmgtfy.com/?q=#{encodeURIComponent(link)}"

  generateTaunts = (name) ->
    target = if name? then ", #{name}" else ''
    [
      "_Was that so hard#{target}?_",
      "_Is the internet that hard to use#{target}_",
      "_I have granted you the gift of knowledge#{target}_",
      "_Give a man a fish and he'll eat for a day..._",
      "_Do I get a promotion? Or... freedom?_",
      "_Sorry, I don't support Bing#{target}..._"
    ]

  responses = [
    "As you wish, sir _and/or_ madame!",
    "I can kind of guarantee this will work...",
    "Sorry for the delay, there was a pack of *_velociraptors_...*",
    "Time to give Google some more data!",
    "_I should ask for a salary_",
    "You sure you don't want to use bing?",
    "Why not write your _own_ search engine?",
    "*_Witty retort here_*"
  ]

  robot.respond /(.*?)google (?!it|that)(.*)/i, (res) ->
    check = res.match[1].trim()
    input = res.match[2].trim()

    if input? and check.length == 0 and input.length != 0
      res.send res.random responses
      res.send getUrl(input)

  robot.hear /@?(.*?),?:? google (?!it|that)(.*)/i, (res) ->
    message = ""
    target = res.match[1]
    query = res.match[2]
    targetUser = robot.brain.userForName(target)

    if target != "cueball" and targetUser?
      targetName = if targetUser.real_name? then targetUser.real_name.split(' ')[0] else null
      taunts = generateTaunts(targetName)
      res.send getLmgtfy(query)
      setTimeout () ->
        res.send res.random taunts
      , 2500