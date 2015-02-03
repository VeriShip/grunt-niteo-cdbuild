grunt-niteo-cdbuild (It's FUN!)
===================
[![Build status](https://ci.appveyor.com/api/projects/status/2momxn2atsvys1ht/branch/master?svg=true)](https://ci.appveyor.com/project/NiteoBuildBot/grunt-niteo-cdbuild/branch/master)
[![Build Status](https://travis-ci.org/NiteoSoftware/grunt-niteo-cdbuild.svg?branch=master)](https://travis-ci.org/NiteoSoftware/grunt-niteo-cdbuild)

This is a grunt extension that we use with our continuously deployments/integrations.

In order to create a continuous delivery pipeline, we need to be able to plug and play the tasks that need to be run. Those tasks come in many varieties, but can most likely be categorized into two different goals.

- Tasks that affect state
- or tasks that affect environments

Tasks that affect state are tasks that you use to make sure that everything is going smoothly within your build. Making sure that particular properties exist, making sure that dependent packages are installed, or making sure tests pass are some examples.

Tasks that affect environments are used to build, alter, or destroy virtual environments that our build artifacts are going to run on.

You can further categorize these tasks into five more categories.

- Tasks that you need to run at the beginning of a run and don't have any affect on any environments.
- Tasks that you need to provision an environment
- Tasks that are dependent on an environment
- Tasks that clean up the environment
- Tasks that you need at the end of a run and don't have any affect on any environments.

I've laid out these five in the order they're in on purpose. These five categories directly correlate into the broadest of steps our continuous delivery pipeline runs in.

- Pre-Setup Tasks
- Setup Tasks
- Test Tasks
- Teardown Tasks
- Post-Teardown Tasks

**Pre-Setup Tasks**

These tasks are tasks that only affect state, need to be ran at the beginning of the run, and do not affect any environments. A good example of these kinds of tasks are tasks that make sure dependencies exist before any build artifacts are created.

For that matter, building application artifacts would also be considered a *Pre-Setup* task. This is a little confusing, I know, but bare with me. Running your build (and by build here, I mean clicking on *build* within an IDE for example.) while you're developing isn't the same thing as performing a full *continuous delivery* pipeline. Although, those builds can be complex in themselves, they are not concerned with building up a *production-like* environment and testing your build artifacts within that environment.

The *Continuous Delivery* pipeline is meant to facilitate that.

**Setup Tasks**

Setup tasks are meant to ready the environment(s) that will be used to test your build artifacts within. Such as calling [vagrant up](). Having a task that would do this would need to be categorized within the Setup Tasks category.

**Test Tasks**

Once the production-like environment(s) are ready, tasks that need to interact with that environment are run. For example:

- Deploying your build artifacts to the production-like environments.
- Running tests against those build artifacts.
- Reporting on those tests. etc...

**Teardown Tasks**

Since the environment needs to exist across multiple tasks, we use this step to make sure we clean up any leftovers of that environment. Because of that, this step has special meaning that we'll get into a little later.

**Post-Teardown**

These tasks are tasks that only affect state, need to be ran at the end of the run and do not affect any environments

**Why are teardown tasks so special?**

If our *continuous delivery* run provisions [AWS EC2](http://aws.amazon.com/ec2/) and uses those instances to deploy it's artifacts and test those artifacts, we don't want those instances to exist after the run completes. Even if the run was not a success. (Especially if the run was not a success.)

Normally, if an error is encountered within a task, the run stops immediately. This makes sure that we [fail fast](http://en.wikipedia.org/wiki/Fail-fast). However, we need our production-like environment to exist across multiple tasks and steps. So we need to make sure that all tasks associated with cleaning up those environments are ran if those environments exist.

Because of this, any error encountered within the *Setup* and *Test* steps will not immediately fail the run. Instead, after the failing task, the current task queue is cleared out and the *Teardown* step tasks are queued. Each task within this step is ran regarless of their success or failure as well.

So, unless the *Teardown* tasks are poorly written and fail before their goal is accomplished, the environment(s) should be cleaned up no matter the outcome of the run.

Installation
------------
```
npm install grunt-niteo-cdbuild --save-dev
```

Usage
-----
```js
// Register the tasks
grunt.loadNpmTasks('grunt-niteo-cdbuild');

// Register the default task to run the cdbuild task.
grunt.registerTask('default', [ 'cdbuild' ]);

// Here we register a task to run in the pre-setup step.
grunt.option('preSetupTasks').push('taskNameToRunInSetup');

// Here we register a task to run in the setup step.
grunt.option('setupTasks').push('taskNameToRunInPreSetup');

// Here we register a task to run in the test step.
grunt.option('testTasks').push('taskNameToRunInTest');

// Here we register a task to run in the teardown step.
grunt.option('teardownTasks').push('taskNameToRunInTeardown');

// Here we register a task to run in the setup step.
grunt.option('postTeardownTasks').push('taskNameToRunInPostTeardown');
```

