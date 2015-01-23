Q = require 'q'
_ = require 'lodash'
path = require 'path'
should = require 'should'

grunt = null

describe 'grunt.cdBuild', ->

	beforeEach ->
		grunt = 
			option: ()->
			registerTask: ()->
			registerMultiTask: () ->
			task: () ->
			file: () ->
			log:
				ok: ->
				writeln: ->
			verbose:
				writeln: ->
		require(path.join( __dirname, "../cdBuild.js"))(grunt)

	describe 'spawnChildAuto',->
		
		it 'should call grunt log ok ',->
			called=false
			grunt.cdBuild.spawnChild = (options,callback)->
				callback(null,{code:0})
			grunt.log=
				ok:()->
					called=true
			grunt.cdBuild.spawnChildAuto(null,->)
			called.should.be.true

		it 'should not call grunt ok ',(done)->
			grunt.cdBuild.spawnChild = (options,callback)->
				callback(null,{code:1})
			grunt.cdBuild.errorHandler=(errorLevel,Message)->
					Message.should.equal 1
					errorLevel.should.equal grunt.cdBuild.errorLevel.error 
			grunt.cdBuild.spawnChildAuto(null,done)

	describe 'errorHandler',->
		it 'should throw error event if current step is setup and level is error',->
			called=false
			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.setup
			grunt.log=
				writeln:->
			grunt.event=
				emit:(cdBuildError,message)->
					called=true
			grunt.cdBuild.errorHandler(grunt.cdBuild.errorLevel.error,"testError")
			called.should.be.true
			
		it 'should throw error event if current step is build and level is error',->
			called=false
			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.build
			grunt.log=
				writeln:->
			grunt.event=
				emit:(cdBuildError,message)->
					called=true
			grunt.cdBuild.errorHandler(grunt.cdBuild.errorLevel.error,"testError")
			called.should.be.true

		it 'should not throw error if current step is not build or setup and level is error', ->

			errorMsg = null
			grunt.fatal = (msg) ->
				errorMsg = msg

			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.teardown

			grunt.cdBuild.errorHandler(grunt.cdBuild.errorLevel.error, "testError")

			errorMsg.should.equal "testError"

		it 'should throw error event if current step is setup and level is warn',->
			called=false
			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.setup
			grunt.log=
				writeln:->
			grunt.event=
				emit:(cdBuildError,message)->
					called=true
			grunt.cdBuild.errorHandler(grunt.cdBuild.errorLevel.warn,"testError")
			called.should.be.true
		it 'should throw error event if current step is build and level is warn',->
			called=false
			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.build
			grunt.log=
				writeln:->
			grunt.event=
				emit:(cdBuildError,message)->
					called=true
			grunt.cdBuild.errorHandler(grunt.cdBuild.errorLevel.warn,"testError")
			called.should.be.true
		it 'should not throw error if current step is not build or setup and level is warn', ->

			warnMsg = null
			grunt.warn = (msg) ->
				warnMsg = msg

			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.preSetup

			grunt.cdBuild.errorHandler(grunt.cdBuild.errorLevel.warning, "testError")

			warnMsg.should.equal "testError"

		it 'should called grunt.warn if current step is not build or setup and level is warn', ->
		
			warnMsg = null
			grunt.warn = (msg) ->
				warnMsg = msg

			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.preSetup

			grunt.cdBuild.errorHandler( grunt.cdBuild.errorLevel.warning, "Dummy Msg" )

			warnMsg.should.equal "Dummy Msg"

		it 'should called grunt.fatal if current step is not build or setup and level is error', ->
		
			fatalMsg = null
			grunt.fatal = (msg) ->
				fatalMsg = msg

			grunt.cdBuild.cdBuildSteps.current = grunt.cdBuild.cdBuildSteps.preSetup

			grunt.cdBuild.errorHandler( grunt.cdBuild.errorLevel.error, "Dummy Msg" )

			fatalMsg.should.equal "Dummy Msg"

	describe 'createJSONStringArray', ->

		it 'should strip \\r from content.', ->

			content = 'line1\r\nline2'
			result = grunt.cdBuild.createJSONStringArray(content)

			for line in result
				line.should.not.containEql '\r'

		it 'should create an array from content where each line is an item in the array.', ->

			content = 'line1\r\nline2\nline3'
			result = grunt.cdBuild.createJSONStringArray(content)

			result[0].should.equal 'line1'
			result[2].should.equal 'line2'
			result[4].should.equal 'line3'

		it 'should add \\n between each item in the array.', ->

			content = 'line1\r\nline2\nline3'
			result = grunt.cdBuild.createJSONStringArray(content)

			result[1].should.equal '\n'
			result[3].should.equal '\n'
			result[5].should.equal '\n'

	describe 'envUp task',->

		it 'should run cloudSetup if isCloudBuild is true', ->

			calledTask = null

			grunt.option = () ->
				true

			grunt.task.run = (taskName) ->
				calledTask = taskName

			grunt.cdBuild.tasks.envUp()

			calledTask.should.equal 'cloudSetup'

		it 'should run localSetup if isCloudBuild is false', ->

			calledTask = null

			grunt.option = () ->
				false

			grunt.task.run = (taskName) ->
				calledTask = taskName

			grunt.cdBuild.tasks.envUp()

			calledTask.should.equal 'localSetup'

		it 'should run localSetup if isCloudBuild is null', ->

			calledTask = null

			grunt.option = () ->
				null

			grunt.task.run = (taskName) ->
				calledTask = taskName

			grunt.cdBuild.tasks.envUp()

			calledTask.should.equal 'localSetup'

		it 'should run localSetup if isCloudBuild is undefined', ->

			calledTask = null

			grunt.option = () ->
				undefined	
				
			grunt.task.run = (taskName) ->
				calledTask = taskName

			grunt.cdBuild.tasks.envUp()

			calledTask.should.equal 'localSetup'

	describe 'envTeardown task', ->

		it 'should run cloudTeardown if isCloudBuild is true', ->

			calledTask = null

			grunt.option = () ->
				true

			grunt.task.run = (taskName) ->
				calledTask = taskName

			grunt.cdBuild.tasks.envTeardown()

			calledTask.should.equal 'cloudTeardown'

		it 'should run localTeardown if isCloudBuild is false', ->

			calledTask = null

			grunt.option = () ->
				false

			grunt.task.run = (taskName) ->
				calledTask = taskName

			grunt.cdBuild.tasks.envTeardown()

			calledTask.should.equal 'localTeardown'

		it 'should run localTeardown if isCloudBuild is null', ->

			calledTask = null

			grunt.option = () ->
				null

			grunt.task.run = (taskName) ->
				calledTask = taskName

			grunt.cdBuild.tasks.envTeardown()

			calledTask.should.equal 'localTeardown'

		it 'should run localTeardown if isCloudBuild is undefined', ->

			calledTask = null

			grunt.option = () ->
				undefined	
				
			grunt.task.run = (taskName) ->
				calledTask = taskName

			grunt.cdBuild.tasks.envTeardown()

			calledTask.should.equal 'localTeardown'

	describe 'gemInstall task',->

		it 'should run spawnChildAuto if gem file is found', ->

			called = false
			grunt.cdBuild.tasks.async = () ->

			grunt.file.exists = () ->
				true

			grunt.cdBuild.spawnChildAuto = () ->
				called = true

			grunt.cdBuild.tasks.gemInstall()

			called.should.be.true

		it 'should log ok if no gemfile is found', ->

			called = false

			grunt.file.exists = () ->
				false
			grunt.log.ok = () ->
				called = true

			grunt.cdBuild.tasks.gemInstall()

			called.should.be.true

	describe 'berksInstall task',->

		it 'should run spawnChildAuto if berksfile is found', ->

			called = false
			grunt.cdBuild.tasks.async = () ->

			grunt.file.exists = () ->
				true

			grunt.cdBuild.spawnChildAuto = () ->
				called = true

			grunt.cdBuild.tasks.berksInstall()

			called.should.be.true

		it 'should log ok if no berksfile is found', ->

			called = false
			
			grunt.file.exists = () ->
				false
			grunt.log.ok = () ->
				called = true

			grunt.cdBuild.tasks.berksInstall()

			called.should.be.true

	describe 'vagrantUp',->

		it 'should run spawnChildAuto if vagrantfile is found', ->

			called = false
			grunt.cdBuild.tasks.async = () ->

			grunt.file.exists = () ->
				true

			grunt.cdBuild.spawnChildAuto = () ->
				called = true

			grunt.cdBuild.tasks.vagrantUp()

			called.should.be.true

		it 'should log ok if no vagrantfile is found', ->

			called = false
			
			grunt.file.exists = () ->
				false
			grunt.log.ok = () ->
				called = true

			grunt.cdBuild.tasks.vagrantUp()

			called.should.be.true

	describe 'vagrantTeardown task',->

		it 'should run spawnChildAuto if vagrantfile is found', ->

			called = false
			grunt.cdBuild.tasks.async = () ->

			grunt.file.exists = () ->
				true

			grunt.cdBuild.spawnChildAuto = () ->
				called = true

			grunt.cdBuild.tasks.vagrantTeardown()

			called.should.be.true

		it 'should log ok if no vagrantfile is found', ->

			called = false
			
			grunt.file.exists = () ->
				false
			grunt.log.ok = () ->
				called = true

			grunt.cdBuild.tasks.vagrantTeardown()

			called.should.be.true

	describe 'cf_createTemplateData task', ->

		it 'should populate grunt.option(\'cloudFormationTemplateData\') with an empty object if no files exist.', ->

			optionName = null
			optionValue = null

			grunt.file.exists = () ->
				false

			grunt.option = (name, value) ->
				optionName = name
				optionValue = value

			grunt.cdBuild.tasks.filesSrc = [ 'some file', 'c:\\Some Other File.png' ]

			grunt.cdBuild.tasks.cf_createTemplateData()

			optionName.should.equal 'cloudFormationTemplateData'
			optionValue.should.eql { }

		it 'should pass file content to grunt.template.process, stringify it, then place it in a camel case property on data.', ->
			
			optionValue = null
			processedContent = 'processed file contents'

			grunt.file.exists = () ->
				true

			grunt.option = (name, value) ->
				optionValue = value

			grunt.file.read = () ->
				'file contents'

			grunt.template = 
				process: () ->
					processedContent

			grunt.cdBuild.tasks.filesSrc = [ 'some file' ]

			grunt.cdBuild.tasks.cf_createTemplateData()

			(optionValue.someFile).should.not.be.null
			optionValue.someFile.should.eql grunt.cdBuild.createJSONStringArray(processedContent)

		it 'should pass file content to grunt.template.process, stringify it, then place it in a camel case property on data. (multi-file)', ->
			
			optionValue = null
			processedContent1 = 'processed file contents'
			processedContent2 = 'processed file contents 2'
			processedContent = [processedContent1, processedContent2 ]

			grunt.file.exists = () ->
				true

			grunt.option = (name, value) ->
				optionValue = value

			grunt.file.read = () ->
				'file contents'

			grunt.template = 
				process: () ->
					processedContent.shift()

			grunt.cdBuild.tasks.filesSrc = [ 'some file', 'some file 2' ]

			grunt.cdBuild.tasks.cf_createTemplateData()

			(optionValue.someFile).should.not.be.null
			optionValue.someFile.should.eql grunt.cdBuild.createJSONStringArray(processedContent1)
			(optionValue.someFile2).should.not.be.null
			optionValue.someFile2.should.eql grunt.cdBuild.createJSONStringArray(processedContent2)

	describe 'cf_createTemplate task', ->

		it 'should call error handler if file length is zero', ->

			calledLevel = null

			grunt.cdBuild.tasks.filesSrc = [ ]

			grunt.cdBuild.tasks.name = "Some Name"

			grunt.cdBuild.errorHandler = (level) ->
				calledLevel = level

			grunt.cdBuild.tasks.cf_createTemplate()

			calledLevel.should.equal grunt.cdBuild.errorLevel.warning

		it 'should call error handler if file does not exist', ->

			calledLevel = null

			grunt.cdBuild.tasks.filesSrc = [ 'some file' ]

			grunt.cdBuild.tasks.name = "Some Name"

			grunt.file.exists = () ->
				false

			grunt.cdBuild.errorHandler = (level) ->
				calledLevel = level

			grunt.cdBuild.tasks.cf_createTemplate()

			calledLevel.should.equal grunt.cdBuild.errorLevel.warning
			
		it 'should call grunt.template.process with file content and data', ->

			fileContent = '{"file": "contents"}'
			processContent = null
			processData = null
			dataObject = 
				someproperty: "tada!"

			grunt.file.exists = () ->
				true

			grunt.file.read = () ->
				fileContent

			grunt.option = () ->
				dataObject

			grunt.template = 
				process: (content, data) ->
					processContent = content
					processData = data
					content

			grunt.cdBuild.tasks.filesSrc = [ 'some file' ]

			grunt.cdBuild.tasks.cf_createTemplate()

			processContent.should.equal fileContent
			processData.should.eql {data:dataObject}

		it 'should put JSON content into grunt.option(\'cloudFormationTemplate\')', ->

			fileContent = '{"file": "contents"}'
			processedContent = null
			dataObject = 
				someproperty: "tada!"

			grunt.file.exists = () ->
				true

			grunt.file.read = () ->
				fileContent

			grunt.option = (name, value) ->
				if name is 'cloudFormationTemplate'
					processedContent = value
				dataObject

			grunt.template = 
				process: (content, data) ->
					fileContent

			grunt.cdBuild.tasks.filesSrc = [ 'some file' ]

			grunt.cdBuild.tasks.cf_createTemplate()

			processedContent.should.eql JSON.parse(fileContent)
		 
