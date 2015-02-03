cdbuild.litcoffee
-----------------

	colors = require 'colors'

	module.exports = (grunt) =>

If the niteo namespace is not defined yet, we make sure to define it.  (Yes, [NiteoSoftware](https://github.com/NiteoSoftware) has more than one plugin that we use in our builds.)

		if not grunt.niteo?
			grunt.niteo = { }

		grunt.niteo.cdBuild = 

This property represents which of the five steps the build is currently in.  Further down the file, you'll see that this is set when the *Pre-Setup*,*Setup*,*Test*,*Teardown*, and *Post-Teardown* tasks are run.

			currentStep: 0

We need to be able to keep track of failures when we're in the *Setup* and *Test* steps.  This property is where we store them.

			buildFailures: [ ]

During development it was nice to see what tasks were being queued to run for each step.  That's where this method came from.

			printQueue: (name) ->
				if grunt.option(name).length > 0
					grunt.log.ok "Queued to run: #{grunt.option(name)}"
				else
					grunt.log.ok "There are no registered tasks for this step.  Skipping..."


This method handles the cleanup when the inevitable happens.  (When we encounter an error.)  Notice that it's queuing up the *report* task at the end.

			queueTeardown: ->
				grunt.task.clearQueue()
				grunt.task.run 'teardown'
				grunt.task.run 'report'

This method aptly *handles* control flow when an error is encountered.  The error 'object' that is being stored contains the original error information along with the appropriate grunt failure method that would 'normally' be called if our extension wasn't switching things around.  You'll see that if the current step is 0 (*Pre-Setup*) or 4 (*Post-Teardown*) it immediatly calls the 'normal' grunt method.  That way grunt handles the error for us in those situations.  However, if the current step is 1 (*Setup*) or 2 (*Test*) and we're not forcing our way past warnings, the *Teardown* tasks are queued.

			handler: (e, errcode, target, isWarning) ->
				@buildFailures.push [e, errcode, target, isWarning ? false]
				msg = String(e.message || e)
				if @currentStep == 0 or @currentStep == 4
					return target(e, errcode)
				
				grunt.log.error msg

				if (@currentStep == 1 or @currentStep == 2) and not (grunt.option('force') and isWarning)
					@queueTeardown()

This method is called at the end of the build to make sure that build failure happens if it needs to.  If there are any saved failure messages from previous steps, this method cycles through them and let's grunt handle them.

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

We place the actual task code in these methods to make them easier to test.

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

Here we make sure that we save the old `grunt.fail.fatal` and `grunt.fail.warn` implementations.  Also, we define the new implementations that will be used when errors are encountered.

		grunt.fail._oldFatal = grunt.fail.fatal
		grunt.fail._newFatal = (e, errcode) ->
			grunt.niteo.cdBuild.handler(e, errcode, grunt.fail._oldFatal)
		grunt.fail._oldWarn = grunt.fail.warn
		grunt.fail._newWarn = (e, errcode) ->
			grunt.niteo.cdBuild.handler(e, errcode, grunt.fail._oldWarn, true)

The definitions of the tasks

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