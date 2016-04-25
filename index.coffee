
fs = require "fs-extra"
_ = require "underscore"
path = require "path"
async = require "async"

flatsplat = (list) ->
	if list.length is 1 and _.isArray(list[0])
		list[0]
	else
		list

# prepend "bower_components/" to an array of path elements
inBowerDir = (pathParts...) ->
	pathParts = ["bower_components/"].concat(flatsplat(pathParts))
	_path = path.join.apply null, pathParts
	# console.log _path
	_path


# load and parse json file
readJSON = (filePath, cb) ->
	fs.readFile filePath, "utf8", (err, res) ->
		_json = JSON.parse(res)
		cb null, _json

# given the parsed JSON data, extract the "main" property
# and prepend the appropriate path.
extractMain = (filePath, data, cb) ->
	_main = data.main

	# handle case where _main has a relative
	# path like "./lib/someScript.js",
	# which will incorrectly resolve to root package dir.
	unless _main?
		return null
	relativeRegex = /^\.\/(.+)$/im
	_match = relativeRegex.exec _main
	if _match?
		_main = _match[1]

	#console.log _main
	#console.log filePath
	_pd = path.dirname(filePath)
	#console.log _pd
	mainPath = path.join( path.dirname(filePath), _main )
	#console.log mainPath
	mainPath

# given component's folder name, get the full path to
# the component's main script
mainFromFolder = (folderName, cb) ->
	_filePath = inBowerDir(folderName, ".bower.json")
	readJSON _filePath, (err, pkg) ->
		mainPath = extractMain(_filePath, pkg)
		if mainPath?
			cb null, {component: folderName, main: mainPath}
		else
			_filePath = inBowerDir(folderName, "package.json")
			readJSON _filePath, (err, pkg) ->
				mainPath = extractMain(_filePath, pkg)
				cb null, {component: folderName, main: mainPath}




copyScript = (scriptRef, outputDir, cb) ->
	scriptPath = scriptRef.main
	outputPath = path.join(outputDir, scriptRef.component) + ".js"
	fs.copy scriptPath, outputPath, (err) ->
		cb null, {src: scriptPath, dest: outputPath}

copyScriptTo = (outputDir) ->
	(scriptRef, cb) ->
		copyScript scriptRef, outputDir, cb

# copy components' main scripts to a target dir
copyComponents = (options, cb) -> 
	_opts = _.clone(options)
	_opts.src ?= "./bower_components"
	unless _opts.dest?
		throw new Error("No destination specified.")

	_copyFn = ->
		fs.readdir _opts.src, (err, folders) ->
			async.map folders, mainFromFolder, (err, completed) ->
				async.map completed, copyScriptTo(_opts.dest), (err, copied) ->
					cb null, copied
	fs.exists _opts.dest, (exists) ->
		if exists
			_copyFn()
		else
			fs.mkdirs _opts.dest, (err) ->
				_copyFn()

# get a list of component names and corresponding main scripts
resolveComponents = (bowerDir, cb) ->
	if _.isFunction(bowerDir)
		cb = bowerDir
		bowerDir = "./bower_components"
	fs.readdir bowerDir, (err, folders) ->
		async.map folders, mainFromFolder, (err, resolved) ->
			cb null, resolved

module.exports =
	copyComponents: copyComponents
	resolveComponents: resolveComponents

