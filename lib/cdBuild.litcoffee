cdBuild.js
==========

*Requires*

	colors = require 'colors'
	fs = require 'fs'
	moment = require 'moment'
	niteoaws = require 'niteoaws'
	S = require 'string'
	path = require 'path'
	assert = require 'assert'
	_ = require 'lodash'

	module.exports = (grunt) ->

cdBuildSteps
------------

These enumerations help the build pipeline keep track of where in the pipeline the current task is.  The errorHandler only kicks in if the pipeline is in the `setup` or `build` steps.

		

grunt.cdbuild
-------------

		grunt.cdBuild =

*cdBuildSteps*

			cdBuildSteps: 
				preSetup: 0
				setup: 1
				build: 2
				teardown: 3
				postTeardown: 4
				current: null

*errorEventName*

			errorEventName: "cdBuildError"
				
*errorLevel*

			errorLevel:
				warning:0
				error:1
				
*errorHandler*

			errorHandler:(level,message) ->
				if @cdBuildSteps.current is @cdBuildSteps.setup or @cdBuildSteps.current is @cdBuildSteps.build
					if level == @errorLevel.warning
						grunt.log.writeln colors.yellow(message)
					else if level == @errorLevel.error
						grunt.log.writeln colors.red(message)
					grunt.event.emit(@errorEventName, message)
				else
					if level is @errorLevel.warning
						grunt.warn message
					else if level is @errorLevel.error
						grunt.fatal message
				
*spawnChild*

			spawnChild: (options, callback) ->
				if options.cmd?
					grunt.log.writeln colors.bold.underline.white "Spawning #{options.cmd}"
				child = grunt.util.spawn options, callback
				child.stdout.on 'data', (buf) ->
					grunt.log.write colors.gray(String(buf))
				child.stderr.on 'data', (buf) ->
					grunt.log.write colors.red(String(buf))
				
*spawnChildAuto*

			spawnChildAuto: (options, done) ->
				@spawnChild options, (err, result) =>
					if result.code != 0 
						if err?
							grunt.log.writeln colors.red err
						@errorHandler @errorLevel.error, result.code
					else
						grunt.log.ok "Exited with code 0"

					done()
				
*createJSONStringArray*

			createJSONStringArray: (content) ->
				result = [ ]
				for item in S(content).strip('\r').split('\n')
					result.push item
					result.push '\n'

				result
				
*generateRunTag*

			generateRunTag: () ->
				"CDBuild#{moment().format("YYYYMMDDhhmmss")}#{process.env.COMPUTERNAME || process.env.HOSTNAME}"
				
*tasks*

			tasks:
				
*envUp*

				envUp: () ->
					if grunt.option('isCloudBuild')
						grunt.task.run 'cloudSetup'
					else
						grunt.task.run 'localSetup'
				
*envTeardown*

				envTeardown: () ->
					if grunt.option('isCloudBuild')
						grunt.task.run 'cloudTeardown'
					else
						grunt.task.run 'localTeardown'
				
*gemInstall*

				gemInstall: () ->
					if grunt.file.exists 'gemfile'

						grunt.cdBuild.spawnChildAuto {
								cmd: "bundle"
								args: ["install"]
							}, @async()
					else
						grunt.log.ok colors.gray("There is no gemfile, so skipping...")
				
*berksInstall*

				berksInstall: () ->
					if grunt.file.exists 'berksfile'

						grunt.cdBuild.spawnChildAuto {
								cmd: "berks"
								args: ["install"]
							}, @async()
					else
						grunt.log.ok colors.gray("There is no berksfile, so skipping...")
				
*vagrantUp*

				vagrantUp: () ->
					if grunt.file.exists 'vagrantfile'

						grunt.cdBuild.spawnChildAuto {
								cmd: "vagrant"
								args: ["up"]
							}, @async()
					else
						grunt.log.ok colors.gray("There is no vagrantfile, so skipping...")
				
*vagrantTeardown*

				vagrantTeardown: () ->

					if grunt.file.exists 'vagrantfile'

						grunt.cdBuild.spawnChildAuto {
								cmd: "vagrant"
								args: ["destroy", "-f"]
							}, @async()
					else
						grunt.log.ok colors.gray("There is no vagrantfile, so skipping...")
				
*cf_validateTemplate*

				cf_validateTemplate: () ->
					done = @async()

					cloudFormationProvider = new niteoaws.cloudFormationProvider.factory grunt.option("cf_region")

					grunt.log.subhead "Validating Template"
					cloudFormationProvider.validateTemplate(JSON.stringify(grunt.option("cloudFormationTemplate")))
						.done (data) ->
								grunt.log.ok "Template is Valid."
								grunt.verbose.writeln data
								done()
							, (err) ->
								grunt.cdBuild.errorHandler grunt.cdBuild.errorLevel.error, err
								done()
				
*cf_createStack*

				cf_createStack: () ->

					done = @async()
					niteoawsCF = new niteoaws.cloudFormationProvider.factory grunt.option("cf_region")

					grunt.log.subhead "Creating Stack #{grunt.option("runTag")}"
					niteoawsCF.createStack(grunt.option("runTag"), JSON.stringify(grunt.option("cloudFormationTemplate")), grunt.option("cloudFormationParameters"))
						.done (data) ->
								grunt.log.ok "Success"
								grunt.verbose.writeln data
								done()
							, (err) ->
								grunt.cdBuild.errorHandler grunt.cdBuild.errorLevel.error, err
								done()
							, (progress) ->
								grunt.log.writeln colors.gray("#{moment().format()}: #{progress}")
				
*cf_deleteStack*

				cf_deleteStack: () ->

					done = @async()
					niteoawsCF = new niteoaws.cloudFormationProvider.factory grunt.option("cf_region")

					grunt.log.subhead "Deleting Stack #{grunt.option("runTag")}"
					niteoawsCF.deleteStack(grunt.option("runTag"))
						.done (data) ->
								grunt.log.ok "Success"
								grunt.verbose.writeln data
								done()
							, (err) ->
								grunt.cdBuild.errorHandler grunt.cdBuild.errorLevel.error, err
								done()
							, (progress) ->
								grunt.log.writeln colors.gray("#{moment().format()}: #{progress}")
				
*cf_createTemplateData*

				cf_createTemplateData: () ->
					data = grunt.option("cloudFormationTemplateData") or { }

					for filePath in @filesSrc
						if grunt.file.exists filePath
							content = grunt.file.read filePath, { encoding: "utf8" }
							id = S(path.basename filePath).stripPunctuation().slugify().camelize()
							data[id] = grunt.cdBuild.createJSONStringArray(grunt.template.process content)

					grunt.verbose.writeln colors.gray(JSON.stringify(data, null, 4))
					grunt.option("cloudFormationTemplateData", data)
				
*cf_createTemplate*

				cf_createTemplate: () ->

					if @filesSrc.length is 0
						grunt.cdBuild.errorHandler grunt.cdBuild.errorLevel.warning, "#{@name} must define a template file."
						return

					filePath = @filesSrc[0]
					if not grunt.file.exists filePath
						grunt.cdBuild.errorHandler grunt.cdBuild.errorLevel.warning, "#{filePath} does not exist."
						return

					data = grunt.option("cloudFormationTemplateData") or { }
					grunt.verbose.writeln colors.gray(JSON.stringify(data, null, 4))
					content = grunt.file.read filePath, { encoding: "utf8" }
					content = grunt.template.process content, { data: data }
					grunt.verbose.writeln colors.gray(content)
					grunt.option("cloudFormationTemplate", JSON.parse(content))

Properties
----------

		grunt.option("runTag", grunt.option("runTag") || grunt.cdBuild.generateRunTag())
		grunt.option("isCloudBuild", grunt.option("isCloudBuild") || false)
		grunt.option("cloudFormationTemplate", grunt.option("cloudFormationTemplate") || { })
		grunt.option("cloudFormationParameters", grunt.option("cloudFormationParameters") || [ ])
		grunt.option("cd_presetupTasks", grunt.option("cd_presetupTasks") || [ 'printRunTag', 'gemInstall', 'berksInstall' ])
		grunt.option("cd_setupTasks", grunt.option("cd_setupTasks") || [ 'envUp' ])
		grunt.option("cd_buildTasks", grunt.option("cd_buildTasks") || [ ])
		grunt.option("cd_teardownTasks", grunt.option("cd_teardownTasks") || [ 'envTeardown' ])
		grunt.option("cd_postteardownTasks", grunt.option("cd_postteardownTasks") || [ ])

		grunt.option("cd_localSetupTasks", grunt.option("cd_localSetupTasks") || [ 'vagrantUp' ] )
		grunt.option("cd_localTeardownTasks", grunt.option("cd_localTeardownTasks") || [ 'vagrantTeardown' ] )

		grunt.option("cd_cloudSetupTasks", grunt.option("cd_cloudSetupTasks") || ['_createTemplateData', '_createTemplate', 'cf_validateTemplate', 'cf_createStack'] )
		grunt.option("cd_cloudTeardownTasks", grunt.option("cd_cloudTeardownTasks") || ['cf_deleteStack'] )

Build Tasks
-----------

		grunt.registerTask 'cdbuild', [ 'setupErrorHandler', 'presetup', 'setup', 'build', 'teardown', 'postteardown' ]

		#	------------------------------------------------------
		#	envUp
		#	------------------------------------------------------
		grunt.registerTask 'setupErrorHandler',() ->
			grunt.event.on grunt.cdBuild.errorEventName,()->
				grunt.task.clearQueue()
				grunt.task.run 'teardown'

		#	------------------------------------------------------
		#	envUp
		#	------------------------------------------------------
		grunt.registerTask 'presetup', () ->
			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.preSetup
			grunt.task.run( grunt.option "cd_presetupTasks" )

		#	------------------------------------------------------
		#	envUp
		#	------------------------------------------------------
		grunt.registerTask 'setup', () ->
			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.setup
			grunt.task.run( grunt.option "cd_setupTasks" )

		#	------------------------------------------------------
		#	envUp
		#	------------------------------------------------------
		grunt.registerTask 'build', () ->
			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.build
			grunt.task.run( grunt.option "cd_buildTasks" )

		#	------------------------------------------------------
		#	envUp
		#	------------------------------------------------------
		grunt.registerTask 'teardown', () ->
			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.teardown
			grunt.task.run( grunt.option "cd_teardownTasks" )

		#	------------------------------------------------------
		#	envUp
		#	------------------------------------------------------
		grunt.registerTask 'postteardown', () ->
			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.postTeardown
			grunt.task.run( grunt.option "cd_postteardownTasks" )

		#	------------------------------------------------------
		#	envUp
		#	------------------------------------------------------
		grunt.registerTask 'envUp', grunt.cdBuild.tasks.envUp

		#	------------------------------------------------------
		#	envTeardown
		#	------------------------------------------------------
		grunt.registerTask 'envTeardown', grunt.cdBuild.tasks.envTeardown

		#	------------------------------------------------------
		#	localSetup
		#	------------------------------------------------------
		grunt.registerTask 'localSetup', () ->

			grunt.task.run grunt.option("cd_localSetupTasks") 

		#	------------------------------------------------------
		#	cloudSetup
		#	------------------------------------------------------
		grunt.registerTask 'cloudSetup', () ->

			grunt.task.run grunt.option("cd_cloudSetupTasks") 
		
		#	------------------------------------------------------
		#	localTeardown
		#	------------------------------------------------------
		grunt.registerTask 'localTeardown', () ->
			
			grunt.task.run grunt.option("cd_localTeardownTasks") 

		#	------------------------------------------------------
		#	cloudTeardown
		#	------------------------------------------------------
		grunt.registerTask 'cloudTeardown', () ->
			
			grunt.task.run grunt.option("cd_cloudTeardownTasks") 

		#	------------------------------------------------------
		#	printRunTag
		#	------------------------------------------------------
		grunt.registerTask 'printRunTag', () ->
			grunt.log.ok colors.gray("RunTag: #{grunt.option("runTag")}")

		#	------------------------------------------------------
		#	gemInstall
		#	------------------------------------------------------
		grunt.registerTask 'gemInstall', grunt.cdBuild.tasks.gemInstall

		#	------------------------------------------------------
		#	berksInstall
		#	------------------------------------------------------
		grunt.registerTask 'berksInstall', grunt.cdBuild.tasks.berksInstall

		#	------------------------------------------------------
		#	vagrantUp
		#	------------------------------------------------------
		grunt.registerTask 'vagrantUp', grunt.cdBuild.tasks.vagrantUp

		#	------------------------------------------------------
		#	vagrantTeardown
		#	------------------------------------------------------
		grunt.registerTask 'vagrantTeardown', grunt.cdBuild.tasks.vagrantTeardown

		#	------------------------------------------------------
		#	cf_validateTemplate
		#	------------------------------------------------------
		grunt.registerTask 'cf_validateTemplate', grunt.cdBuild.tasks.cf_validateTemplate

		#	------------------------------------------------------
		#	cf_createStack
		#	------------------------------------------------------
		grunt.registerTask 'cf_createStack', grunt.cdBuild.tasks.cf_createStack

		#	------------------------------------------------------
		#	cf_deleteStack
		#	------------------------------------------------------
		grunt.registerTask 'cf_deleteStack', grunt.cdBuild.tasks.cf_deleteStack

		#	------------------------------------------------------
		#	_createTemplateData
		#	------------------------------------------------------
		grunt.registerTask '_createTemplateData', () ->
			if not _.isEmpty(grunt.config.get('cf_createTemplateData'))
				grunt.task.run 'cf_createTemplateData'
		
		#	------------------------------------------------------
		#	_createTemplate
		#	------------------------------------------------------
		grunt.registerTask '_createTemplate', () ->
			if not _.isEmpty(grunt.config.get('cf_createTemplate'))
				grunt.task.run 'cf_createTemplate'

		#	------------------------------------------------------
		#	cf_createTemplateData
		#	------------------------------------------------------
		grunt.registerMultiTask 'cf_createTemplateData', grunt.cdBuild.tasks.cf_createTemplateData

		#	------------------------------------------------------
		#	cf_createTemplate
		#	------------------------------------------------------
		grunt.registerMultiTask 'cf_createTemplate', grunt.cdBuild.tasks.cf_createTemplate
			

