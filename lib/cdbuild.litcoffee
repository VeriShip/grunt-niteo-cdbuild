	colors = require 'colors'

	module.exports = (grunt) =>

		if not grunt.niteo?
			grunt.niteo = { }

		grunt.niteo.cdBuild = 
			currentStep: 0
			buildFailures: [ ]
			printQueue: (name) ->
				if grunt.option(name).length > 0
					grunt.log.ok "Queued to run: #{grunt.option(name)}"
				else
					grunt.log.ok "There are no registered tasks for this step.  Skipping..."
			queueTeardown: ->
				grunt.task.clearQueue()
				grunt.task.run 'teardown'
				grunt.task.run 'report'
			handler: (e, errcode, target, isWarning) ->
				@buildFailures.push [e, errcode, target, isWarning ? false]
				msg = String(e.message || e)
				if @currentStep == 0 or @currentStep == 4
					return target(e, errcode)
				
				grunt.log.error msg

				if (@currentStep == 1 or @currentStep == 2) and not (grunt.option('force') and isWarning)
					@queueTeardown()
			report: ->
				if @buildFailures.length > 0
					grunt.log.error "There were issues within the run:"
					grunt.log.error ""
					for failure in @buildFailures
						if failure[3]
							grunt.log.error colors.yellow(String(failure[0].message ? failure[0]))
						else
							grunt.log.error colors.red(String(failure[0].message ? failure[0]))
					grunt.log.error ""
					grunt.log.error "These issues will be iteratted one by one.  The first to fail will cause the rest to not be reported."

					for failure in @buildFailures
						failure[2](failure[0], failure[1])
				else
					grunt.log.ok "There were no failures within the run.  Success"
			tasks:
				preSetup: ->
					grunt.niteo.cdBuild.currentStep = 0
					grunt.option('preSetupTasks').unshift('setupCDBuild')
					grunt.niteo.cdBuild.printQueue('preSetupTasks')
					grunt.task.run grunt.option('preSetupTasks')
				setup: ->
					grunt.niteo.cdBuild.currentStep = 1
					grunt.niteo.cdBuild.printQueue('setupTasks')
					grunt.task.run grunt.option('setupTasks')
				test: ->
					grunt.niteo.cdBuild.currentStep = 2
					grunt.niteo.cdBuild.printQueue('testTasks')
					grunt.task.run grunt.option('testTasks')
				teardown: ->
					grunt.niteo.cdBuild.currentStep = 3
					grunt.niteo.cdBuild.printQueue('teardownTasks')
					grunt.task.run grunt.option('teardownTasks')
				postTeardown: ->
					grunt.niteo.cdBuild.currentStep = 4
					grunt.task.run 'report'
					if grunt.niteo.cdBuild.buildFailures.length == 0
						grunt.niteo.cdBuild.printQueue('postTeardownTasks')
						grunt.task.run grunt.option('postTeardownTasks')
				report: ->
					grunt.niteo.cdBuild.report()
				setupCDBuild: ->
					grunt.fail.fatal = grunt.fail._newFatal
					grunt.fail.warn = grunt.fail._newWarn
					grunt.fatal = grunt.fail._newFatal
					grunt.warn = grunt.fail._newWarn
					grunt.log.ok "Manipulating grunt to work with cdBuild..."

		#Setup error handling
		grunt.fail._oldFatal = grunt.fail.fatal
		grunt.fail._newFatal = (e, errcode) ->
			grunt.niteo.cdBuild.handler(e, errcode, grunt.fail._oldFatal)
		grunt.fail._oldWarn = grunt.fail.warn
		grunt.fail._newWarn = (e, errcode) ->
			grunt.niteo.cdBuild.handler(e, errcode, grunt.fail._oldWarn, true)

		grunt.option 'preSetupTasks', [ ]
		grunt.option 'setupTasks', [ ]
		grunt.option 'testTasks', [ ]
		grunt.option 'teardownTasks', [ ]
		grunt.option 'postTeardownTasks', [ ]

		grunt.registerTask 'cdbuild', ['preSetup', 'setup', 'test', 'teardown', 'postTeardown']
		grunt.registerTask 'preSetup', grunt.niteo.cdBuild.tasks.preSetup
		grunt.registerTask 'setup', grunt.niteo.cdBuild.tasks.setup
		grunt.registerTask 'test', grunt.niteo.cdBuild.tasks.test
		grunt.registerTask 'teardown', grunt.niteo.cdBuild.tasks.teardown
		grunt.registerTask 'postTeardown', grunt.niteo.cdBuild.tasks.postTeardown
		grunt.registerTask 'report', grunt.niteo.cdBuild.tasks.report
		grunt.registerTask 'setupCDBuild', grunt.niteo.cdBuild.tasks.setupCDBuild