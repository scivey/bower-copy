#!/usr/bin/env node

path = require "path"
_mainPath = path.join __dirname, "../index.js"

{resolveComponents, copyComponents} = require _mainPath

{ArgumentParser} = require "argparse"

parser = new ArgumentParser {
	version: "0.0.3"
	addHelp: true
	description: "Copy Bower components' main scripts to a target directory."
}

parser.addArgument ["-d", "--dest"], {
	type: "string"
	help: "The target directory."
}

parser.addArgument ["-s", "--src"], {
	type: "string"
	help: "The source directory."
	default: "./bower_components"
}

parser.addArgument ["-r", "--resolve"], {
	default: false
	action: "storeTrue"
	help: "If passed, the main script paths will be printed to STDOUT in JSON format.  No files will be copied."
}

options = parser.parseArgs()

options.src ?= "./bower_components"

if options.resolve
	resolveComponents options.src, (err, components) ->
		console.log components
else
	unless options.dest?
		throw new Error("No destination specified.")


	copyComponents options, (err, copied) ->
		console.log "Success."

	#console.log options
