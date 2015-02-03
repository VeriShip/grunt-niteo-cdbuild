Q = require 'q'
should = require 'should'

grunt = null

getGruntStub = ->
	log:
		writeln: ->
		ok: ->
		error: ->
	verbose:
		writeln: ->
		ok: ->
	fail:
		warn: ->
		fatal: ->
	fatal: ->
	warn: ->
	_options: { }
	option: (key, value) ->
		if value?
			@_options[key] = value
		else
			@_options[key]
	registerTask: ->
	registerMultiTask: ->
	task:
		run: ->
		clearQueue: ->

loadGrunt = (grunt) ->

	(require '../cdbuild.js')(grunt)

beforeEachMethod = ->

	#	Setup the grunt stub.
	grunt = getGruntStub()
	loadGrunt(grunt)

describe 'grunt', ->

	beforeEach beforeEachMethod

	describe 'fail', ->

		it 'should set _oldFatal equal to base grunt fatal method.', ->

			actualE = null
			actualErrorCode = null
			grunt = getGruntStub()
			grunt.fail.fatal = (e, errorCode)->
				actualE = e
				actualErrorCode = errorCode
			loadGrunt(grunt)	

			grunt.fail._oldFatal "some e", "some error code"

			actualE.should.equal "some e"
			actualErrorCode.should.equal "some error code"

		it 'should set _oldWarn equal to base grunt warn method.', ->

			actualE = null
			actualErrorCode = null
			grunt = getGruntStub()
			grunt.fail.warn = (e, errorCode)->
				actualE = e
				actualErrorCode = errorCode
			loadGrunt(grunt)	

			grunt.fail._oldWarn "some e", "some error code"

			actualE.should.equal "some e"
			actualErrorCode.should.equal "some error code"

		describe '_newFatal', ->

			it 'should call grunt.niteo.cdBuild.handler with the appropriate parameters.', ->

				actualE = null
				actualErrorCode = null
				actualFunction = null

				grunt.niteo.cdBuild.handler = (e, errorCode, targetFunction) ->
					actualE = e
					actualErrorCode = errorCode
					actualFunction = targetFunction

				grunt.fail._newFatal "some e", "some code"

				actualE.should.equal "some e"
				actualErrorCode.should.equal "some code"
				actualFunction.should.eql grunt.fail._oldFatal

		describe '_newWarn', ->

			it 'should call grunt.niteo.cdBuild.handler with the appropriate parameters.', ->

				actualE = null
				actualErrorCode = null
				actualFunction = null

				grunt.niteo.cdBuild.handler = (e, errorCode, targetFunction) ->
					actualE = e
					actualErrorCode = errorCode
					actualFunction = targetFunction

				grunt.fail._newWarn "some e", "some code"

				actualE.should.equal "some e"
				actualErrorCode.should.equal "some code"
				actualFunction.should.eql grunt.fail._oldWarn

	describe 'option', ->

		it 'should be prepopulated with an empty array for the key "preSetupTasks"', ->
			grunt.option('preSetupTasks').length.should.equal 0

		it 'should be prepopulated with an empty array for the key "setupTasks"', ->
			grunt.option('setupTasks').length.should.equal 0

		it 'should be prepopulated with an empty array for the key "testTasks"', ->
			grunt.option('testTasks').length.should.equal 0

		it 'should be prepopulated with an empty array for the key "teardownTasks"', ->
			grunt.option('teardownTasks').length.should.equal 0

		it 'should be prepopulated with an empty array for the key "postTeardownTasks"', ->
			grunt.option('postTeardownTasks').length.should.equal 0

	describe 'niteo', ->

		it 'should define the grunt.niteo namespace when it does not already exist.', ->

			grunt.niteo.should.be.ok
			grunt.niteo.cdBuild.should.be.ok

		it 'should not overwrite the grunt.niteo namespace if it is already defined.', ->

			grunt = getGruntStub()
			grunt.niteo = 
				SomeOtherObject: { }

			loadGrunt(grunt)

			grunt.niteo.should.be.ok
			grunt.niteo.cdBuild.should.be.ok
			grunt.niteo.SomeOtherObject.should.be.ok

	describe 'cdBuild', ->

		describe 'queueTeardown', ->

			it 'should clear the current queue.', ->

				called = false
				grunt.task.clearQueue = ->
					called = true

				grunt.niteo.cdBuild.queueTeardown()

				called.should.be.true

			it 'should queue "teardown"', ->

				queuedTasks = [ ]
				grunt.task.run = (name) ->
					queuedTasks.push name

				grunt.niteo.cdBuild.queueTeardown()

				queuedTasks[0].should.equal 'teardown'

			it 'should queue "report"', ->

				queuedTasks = [ ]
				grunt.task.run = (name) ->
					queuedTasks.push name

				grunt.niteo.cdBuild.queueTeardown()

				queuedTasks[1].should.equal 'report'

		describe 'handler', ->

			targetFunction = ->

			it 'should add the error into the "buildFailures" array.', ->

				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction, false

				grunt.niteo.cdBuild.buildFailures[0][0].should.equal "Some Error"
				grunt.niteo.cdBuild.buildFailures[0][1].should.equal "Some ErrorCode"
				grunt.niteo.cdBuild.buildFailures[0][2].should.eql targetFunction
				grunt.niteo.cdBuild.buildFailures[0][3].should.be.false

			it 'should set the error as a warning if true is passed.', ->

				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction, true
				grunt.niteo.cdBuild.buildFailures[0][3].should.be.true 

			it 'should set the error as fatal if false is passed.', ->

				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction, false
				grunt.niteo.cdBuild.buildFailures[0][3].should.be.false 

			it 'should set the error as fatal if null is passed.', ->

				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction, null
				grunt.niteo.cdBuild.buildFailures[0][3].should.be.false 

			it 'should set the error as fatal if undefined is passed.', ->

				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction
				grunt.niteo.cdBuild.buildFailures[0][3].should.be.false 

			it 'should call target function when current step is 0', ->

				actualE = null
				actualErrorCode = null
				targetFunction = (e, errorCode) ->
					actualE = e
					actualErrorCode = errorCode

				grunt.niteo.cdBuild.currentStep = 0
				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction

				actualE.should.equal "Some Error"
				actualErrorCode.should.equal "Some ErrorCode"

			it 'should call target function when current step is 4', ->

				actualE = null
				actualErrorCode = null
				targetFunction = (e, errorCode) ->
					actualE = e
					actualErrorCode = errorCode

				grunt.niteo.cdBuild.currentStep = 4
				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction

				actualE.should.equal "Some Error"
				actualErrorCode.should.equal "Some ErrorCode"

			it 'should not call target function when current step is 1', ->

				called = false
				targetFunction = (e, errorCode) ->
					called = true

				grunt.niteo.cdBuild.currentStep = 1
				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction

				called.should.be.false

			it 'should not call target function when current step is 2', ->

				called = false
				targetFunction = (e, errorCode) ->
					called = true

				grunt.niteo.cdBuild.currentStep = 2
				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction

				called.should.be.false

			it 'should not call target function when current step is 3', ->

				called = false
				targetFunction = (e, errorCode) ->
					called = true

				grunt.niteo.cdBuild.currentStep = 3
				grunt.niteo.cdBuild.handler "Some Error", "Some ErrorCode", targetFunction

				called.should.be.false

			it 'should call "queueTeardown" if the currentStep is 1, the error is a warning, and the run is not forced.', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					false

				grunt.niteo.cdBuild.currentStep = 1
				grunt.niteo.cdBuild.handler "", "", targetFunction, true

				called.should.be.true
			it 'should call "queueTeardown" if the currentStep is 1, the error is fatal, and the run is not forced.', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					false

				grunt.niteo.cdBuild.currentStep = 1
				grunt.niteo.cdBuild.handler "", "", targetFunction, false

				called.should.be.true
			it 'should call "queueTeardown" if the currentStep is 1, the error is fatal, and the run is forced.', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					true

				grunt.niteo.cdBuild.currentStep = 1
				grunt.niteo.cdBuild.handler "", "", targetFunction, false

				called.should.be.true
			it 'should call "queueTeardown" if the currentStep is 2, the error is a warning, and the run is not forced.', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					false

				grunt.niteo.cdBuild.currentStep = 2
				grunt.niteo.cdBuild.handler "", "", targetFunction, true

				called.should.be.true
			it 'should call "queueTeardown" if the currentStep is 2, the error is fatal, and the run is not forced.', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					false

				grunt.niteo.cdBuild.currentStep = 2
				grunt.niteo.cdBuild.handler "", "", targetFunction, false

				called.should.be.true
			it 'should call "queueTeardown" if the currentStep is 2, the error is fatal, and the run is forced.', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					true

				grunt.niteo.cdBuild.currentStep = 2
				grunt.niteo.cdBuild.handler "", "", targetFunction, false

				called.should.be.true
			it 'should not call "queueTeardown" if the currentStep is 1, the error is a warning, and the run is forced.', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					true

				grunt.niteo.cdBuild.currentStep = 1
				grunt.niteo.cdBuild.handler "", "", targetFunction, true

				called.should.be.false
			it 'should not call "queueTeardown" if the currentStep is 2, the error is a warning, and the run is forced.', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					true

				grunt.niteo.cdBuild.currentStep = 2
				grunt.niteo.cdBuild.handler "", "", targetFunction, true

				called.should.be.false
			it 'should not call "queueTeardown" if the currentStep is not 1 or 2. (0)', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					true

				grunt.niteo.cdBuild.currentStep = 0
				grunt.niteo.cdBuild.handler "", "", targetFunction, true

				called.should.be.false
			it 'should not call "queueTeardown" if the currentStep is not 1 or 2. (3)', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					true

				grunt.niteo.cdBuild.currentStep = 3
				grunt.niteo.cdBuild.handler "", "", targetFunction, true

				called.should.be.false
			it 'should not call "queueTeardown" if the currentStep is not 1 or 2. (-1)', ->
				called = false
				grunt.niteo.cdBuild.queueTeardown = ->
					called = true
				grunt.option = ->
					true

				grunt.niteo.cdBuild.currentStep = -1
				grunt.niteo.cdBuild.handler "", "", targetFunction, true

				called.should.be.false

		describe 'report', ->

			it 'should iterate through each item in the buildFailures collection and call the target function of each.', ->

				for i in [0, 10] by 1
					item =  
						called: false
						targetFunction: ->
							@called = true 
					grunt.niteo.cdBuild.buildFailures.push [ "", "", item.targetFunction, false ]
				
				grunt.niteo.cdBuild.report()

				for failure in grunt.niteo.cdBuild.buildFailures
					failure.called.should.be.true

		describe 'tasks', ->

			describe 'preSetup', ->

				it 'should set the current step to 0.', ->

					grunt.niteo.cdBuild.currentStep = 1
					grunt.niteo.cdBuild.tasks.preSetup()
					grunt.niteo.cdBuild.currentStep.should.equal 0

				it 'should queue the preSetupTasks array to run.', ->

					expected = [ 'dummy0', 'dummy2', 'YAY!' ]
					actual = null
					grunt.task.run = (array) ->
						actual = array
					grunt._options.preSetupTasks = expected
					grunt.niteo.cdBuild.tasks.preSetup()
					actual.should.equal expected

				it 'should add the "setupCDBuild" task to the preSetupTasks queue.', ->

					grunt.niteo.cdBuild.tasks.preSetup()
					grunt._options.preSetupTasks[0].should.equal 'setupCDBuild'

			describe 'setup', ->

				it 'should set the current step to 1.', ->

					grunt.niteo.cdBuild.currentStep = 0
					grunt.niteo.cdBuild.tasks.setup()
					grunt.niteo.cdBuild.currentStep.should.equal 1

				it 'should queue the setupTasks array to run.', ->

					expected = [ 'dummy0', 'dummy2', 'YAY!' ]
					actual = null
					grunt.task.run = (array) ->
						actual = array
					grunt._options.setupTasks = expected
					grunt.niteo.cdBuild.tasks.setup()
					actual.should.equal expected

			describe 'test', ->

				it 'should set the current step to 2.', ->

					grunt.niteo.cdBuild.currentStep = 0
					grunt.niteo.cdBuild.tasks.test()
					grunt.niteo.cdBuild.currentStep.should.equal 2

				it 'should queue the testTasks array to run.', ->

					expected = [ 'dummy0', 'dummy2', 'YAY!' ]
					actual = null
					grunt.task.run = (array) ->
						actual = array
					grunt._options.testTasks = expected
					grunt.niteo.cdBuild.tasks.test()
					actual.should.equal expected
					
			describe 'teardown', ->

				it 'should set the current step to 3.', ->

					grunt.niteo.cdBuild.currentStep = 0
					grunt.niteo.cdBuild.tasks.teardown()
					grunt.niteo.cdBuild.currentStep.should.equal 3

				it 'should queue the teardownTasks array to run.', ->

					expected = [ 'dummy0', 'dummy2', 'YAY!' ]
					actual = null
					grunt.task.run = (array) ->
						actual = array
					grunt._options.teardownTasks = expected
					grunt.niteo.cdBuild.tasks.teardown()
					actual.should.equal expected
					
			describe 'postTeardown', ->

				it 'should set the current step to 4.', ->

					grunt.niteo.cdBuild.currentStep = 0
					grunt.niteo.cdBuild.tasks.postTeardown()
					grunt.niteo.cdBuild.currentStep.should.equal 4

				it 'should queue up the "report" task.', ->

					actualTasks = [ ]
					grunt.task.run = (array) ->
						actualTasks.push array
					grunt.niteo.cdBuild.buildFailures.push 'dummy'

					grunt.niteo.cdBuild.tasks.postTeardown()
					actualTasks.should.eql [ "report" ]

				it 'should queue the postTeardownTasks array to run if there are no build failures.', ->

					expected = [ 'dummy0', 'dummy2', 'YAY!' ]
					actualQueue = [ ] 
					grunt.task.run = (array) ->
						actualQueue.push array
					grunt.niteo.cdBuild.buildFailures = [ ]
					grunt._options.postTeardownTasks = expected
					grunt.niteo.cdBuild.tasks.postTeardown()
					actualQueue.should.eql [ 'report', expected ]

				it 'should not queue the postTeardownTasks array to run if there are no build failures.', ->

					actualQueue = [ ] 
					grunt.task.run = (array) ->
						actualQueue.push array
					grunt.niteo.cdBuild.buildFailures = [ 'value' ]
					grunt.niteo.cdBuild.tasks.postTeardown()
					actualQueue.should.eql [ 'report' ]

			describe 'report', ->

				it 'should call grunt.niteo.cdBuild.report.', ->

					called = false
					grunt.niteo.cdBuild.report = ->
						called = true

					grunt.niteo.cdBuild.tasks.report()

					called.should.be.true

			describe 'setupCDBuild', ->

				it 'should set grunt.fail.fatal to grunt.fail._newFatal.', ->
					grunt.niteo.cdBuild.tasks.setupCDBuild()
					grunt.fail.fatal.should.equal grunt.fail._newFatal

				it 'should set grunt.fail.warn to grunt.fail._newWarn.', ->
					grunt.niteo.cdBuild.tasks.setupCDBuild()
					grunt.fail.warn.should.equal grunt.fail._newWarn

				it 'should set grunt.fatal to grunt.fail._newFatal.', ->
					grunt.niteo.cdBuild.tasks.setupCDBuild()
					grunt.fatal.should.equal grunt.fail._newFatal

				it 'should set grunt.warn to grunt.fail._newWarn.', ->
					grunt.niteo.cdBuild.tasks.setupCDBuild()
					grunt.warn.should.equal grunt.fail._newWarn
