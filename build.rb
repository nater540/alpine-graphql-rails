#!/usr/bin/env ruby

require 'bump'
require 'childprocess'
require 'awesome_print'
require 'highline/import'

HighLine.colorize_strings

# Prefer posix_spawn on *nix
ChildProcess.posix_spawn = true

# Store useful information in globals (yeah yeah.... yuck globals!)
$current_version = Bump::Bump.current
$docker_user     = 'nater540'
$docker_image    = 'graphql-ruby'

# Helper method for bumping the version, but not committing, tagging or bundling.
#
# @param [Symbol, String] version The version to bump to.
def bump_it_to(version:)
  Bump::Bump.run(version.to_s, commit: false, bundle: false, tag: false)
  $current_version = Bump::Bump.current
  say("Bumped to version: #{$current_version}!".bold)
end

# Prompts the user to bump the version of the docker image.
#
def prompt_version_bump
  say("Current image version: #{$current_version}".bold)

  choose do |menu|
    menu.header = 'Select a release type'
    # menu.index  = :letter

    menu.choice('Major') { bump_it_to(version: :major) }
    menu.choice('Minor') { bump_it_to(version: :minor) }
    menu.choice('Patch') { bump_it_to(version: :patch) }

    menu.choice('This decision is too hard for me! Exit Now!!') do
      say('Womp Womp'.red.bold)
      exit(0)
    end

    menu.choice('I literally have no clue what this means...') do
      say("#{'#' * 100}".bold)
      say('Semantic Versioning 2.0.0'.bold)

      say(<<~semver)
      Given a version number MAJOR.MINOR.PATCH, increment the:
        1) MAJOR version when you make incompatible API changes,
        2) MINOR version when you add functionality in a backwards-compatible manner, and
        3) PATCH version when you make backwards-compatible bug fixes.
      semver
      say("#{'#' * 100}".bold)

      # Rinse and repeat...
      prompt_version_bump
    end
  end
end

# Creates a new process and attaches it to the current stdio
#
# @param [Array] *args The process arguments.
# @param [Boolean] start Whether or not the process should automatically start.
# @param [Boolean] wait Whether or not to wait until the process finishes (only applicable if `start` is true!)
# @param [Boolean] attach Whether or not the process should inherit the current stdout/stderr.
# @param [String] cwd The current working directory to switch to.
# @param [Hash] environment Any environment variables to set.
# @return [ChildProcess::Process]
def create_process(*args, start: true, wait: true, attach: true, cwd: nil, environment: {})
  process = ChildProcess.build(*args)
  process.io.inherit! if attach

  # Set the working directory
  process.cwd = cwd unless cwd.nil?

  # Set any passed environment variables
  environment.each do |env, value|
    process.environment[env.to_s] = value
  end

  # Start the process if requested
  if start
    process.start
    process.wait if wait
  end

  process
end

# Prompt the user to bump the version of the docker image
# prompt_version_bump

# Build the docker image?
if agree('Build the container locally to ensure everything works? [Y/n]'.bold)
  build_process = create_process('docker', 'build', '-t', "#{$docker_user}/#{$docker_image}:latest", '.')

  # Exit if the docker build process failed
  if build_process.exit_code != 0
    say('Exiting since docker build did not exit with `0`...'.red.bold)
    exit(0)
  end
end

if agree('Push the container to Docker Cloud? [Y/n]'.bold)
  create_process('docker', 'tag', "#{$docker_user}/#{$docker_image}:latest", "#{$docker_user}/#{$docker_image}:#{$current_version}")
  create_process('docker', 'push', "#{$docker_user}/#{$docker_image}:#{$current_version}")
  create_process('docker', 'push', "#{$docker_user}/#{$docker_image}:latest")
end

if agree('Commit and push changes to Github? [Y/n]'.bold)
  message = ask("Commit Message: ") { |quest| quest.default = "\"version #{$current_version}\"" }

  say('Adding changes, committing and pushing...'.blue.bold)
  create_process('git', 'add', '-A', attach: false)
  create_process('git', 'commit', '-m', message, attach: false)
  create_process('git', 'tag', '-a', "#{$current_version}", '-m', message, attach: false)
  create_process('git', 'push', attach: false)
  create_process('git', 'push', '--tags', attach: false)
end
