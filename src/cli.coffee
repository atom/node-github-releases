fs = require 'fs'
optimist = require 'optimist'
prettyjson = require 'prettyjson'
GitHub = require '../lib/github'

options = optimist
  .usage("""
    Usage: github-releases [--tag==<tag>] [--token=<token>] <command> <repo>
  """)
  .alias('h', 'help').describe('help', 'Print this usage message')
  .string('token').describe('token', 'Your GitHub token')
  .string('tag').describe('tag', 'The tag of the release')

print = (error, result) ->
  if error?
    message = error.message ? error
    console.error "Command failed with error: #{message}"
  else
    console.log prettyjson.render(result)

run = (github, command, argv, callback) ->
  switch command
    when 'list-releases'
      github.getReleases print

    when 'get-release'
      getRelease =
        if argv.tag?
          github.getReleaseOfTag.bind github, argv.tag
        else
          github.getLatestRelease.bind github
      getRelease callback

    when 'get-assets'
      getAssets =
        if argv.tag?
          github.getAssetsOfTag.bind github, argv.tag
        else
          github.getLatestAssets.bind github
      getAssets callback

    when 'download-release-assets'
      run github, 'get-assets', argv, (error, assets) ->
        return print(error) if error?
        for asset in assets when asset.state is 'uploaded'
          do (asset) ->
            github.downloadAsset asset, (error, stream) ->
              return console.error("Unable to download #{asset.name}") if error?
              stream.pipe fs.createWriteStream(asset.name)

    else
      console.error "Invalid command: #{command}"

argv = options.argv
if argv._.length < 2 or argv.h
  return options.showHelp()

command = argv._[0]
github = new GitHub(repo: argv._[1], token: argv.token)
run github, command, argv, print
