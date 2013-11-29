fs = require 'fs'
util = require 'util'
optimist = require 'optimist'
GitHub = require '../lib/github'

options = optimist
  .usage("""
    Usage: github-releases [--token=<token>] <command> <repo>
  """)
  .alias('h', 'help').describe('help', 'Print this usage message')
  .alias('t', 'token').describe('token', 'Your GitHub token')

argv = options.argv
if argv._.length < 2 or argv.h
  return options.showHelp()

print = (error, result) ->
  if error?
    message = error.message ? error
    console.error "Command failed with error: #{message}"
  else
    console.log result

command = argv._[0]
github = new GitHub(repo: argv._[1], token: argv.token)
switch command
  when 'list-releases'
    github.getReleases print

  when 'get-latest-release'
    github.getLatestRelease print

  when 'download-latest-release-assets'
    github.getLatestRelease (error, release) ->
      return print(error) if error?
      for asset in release.assets when asset.state is 'uploaded'
        do (asset) ->
          github.downloadAsset asset, (error, stream) ->
            return console.error("Unable to download #{asset.name}") if error?
            stream.pipe fs.createWriteStream(asset.name)

  else
    console.error "Invalid command: #{command}"
