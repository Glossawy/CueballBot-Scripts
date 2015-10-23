# Description:
#   Cueball can now remember using files
# 
# Dependencies:
#   mkdirp
# 
# Configuration:
#   None
# 
# Commands:
# 
# Author:
#   Matthew Crocco

fs = require('fs')
path = require('path')
mkdirp = require('mkdirp')

module.exports = (robot) ->
	brainPath = process.env.CUEBALL_BRAIN_PATH or "/var/hubot"
	brainPath = path.join brainPath, 'cueball-brain.json'

	if not fs.existsSync(brainPath)
		mkdirp.sync path.dirname(brainPath)
		fs.closeSync(fs.openSync(brainPath, 'wx'))

	try
		data = fs.readFileSync brainPath, 'utf-8'
		if data
			robot.brain.mergeData JSON.parse(data)
	catch e
		console.log('failed to read brain!') unless e.code is 'ENOENT'

	robot.brain.on 'save', (data) ->
		fs.writeFileSync brainPath, JSON.stringify(data, null, 4), 'utf-8'
