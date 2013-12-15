
fs = require "fs-extra"
_ = require "underscore"
path = require "path"
async = require "async"

flatsplat = (list) ->
	if list.length is 1 and _.isArray(list[0])
		list[0]
	else
		list

inBowerDir = (pathParts...) ->
	pathParts = ["bower_components/"].concat(flatsplat(pathParts))
	_path = path.join.apply null, pathParts
	console.log _path
	_path

readJSON = (filePath, cb) ->
	fs.readFile filePath, "utf8", (err, res) ->
		_json = JSON.parse(res)
		cb null, _json

extractMain = (filePath, data) ->
	_main = data.main
	mainPath = path.join( path.dirname(filePath), _main )
	mainPath

mainFromFolder = (folderName, cb) ->
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

copyComponents = (options, cb) ->
	_opts = _.clone(options)
	_opts.src ?= "./bower_components"
	unless _opts.dest?
		throw new Error("No destination specified.")
	fs.readdir _opts.src, (err, folders) ->
		async.map folders, mainFromFolder, (err, completed) ->
			async.map completed, copyScriptTo(_opts.dest), (err, copied) ->
				cb null, copied

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

