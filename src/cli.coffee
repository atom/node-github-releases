fs         = require 'fs'
optimist   = require 'optimist'
prettyjson = require 'prettyjson'
minimatch  = require 'minimatch'
GitHub     = require '../lib/github'

options = optimist
  .usage("""
    Usage: github-releases [--tag==<tag>] [--pre] [--filename=<filename>] [--token=<token>] <command> <repo>
  """)
  .alias('h', 'help').describe('help', 'Print this usage message')
  .string('token').describe('token', 'Your GitHub token')
  .string('tag').describe('tag', 'The tag of the release')
  .boolean('pre').describe('pre', 'Is the release a pre-release')
                 .default('pre', false)
  .string('filename').describe('filename', 'The filename of the asset')
                     .default('filename', '*')

print = (error, result) ->
  if error?
    message = error.message ? error
    console.error "Command failed with error: #{message}"
  else
    console.log prettyjson.render(result)

run = (github, command, argv, callback) ->
  switch command
    when 'list'
      filters = {}
      filters.tag_name = argv.tag if argv.tag?
      filters.prerelease = argv.pre
      github.getReleases filters, callback

    when 'show'
      run github, 'list', argv, (error, releases) ->
        return callback(error) if error?
        return callback(new Error("No matching release can be found")) if releases.length is 0
        callback null, releases[0]

    when 'download'
      run github, 'show', argv, (error, release) ->
        return callback(error) if error?
        for asset in release.assets when asset.state is 'uploaded' and minimatch asset.name, argv.filename
          do (asset) ->
            github.downloadAsset asset, (error, stream) ->
              return console.error("Unable to download #{asset.name}") if error?
              stream.pipe fs.createWriteStream(asset.name)

    when 'download-all'
      run github, 'list', argv, (error, releases) ->
        return callback(error) if error?
        for release in releases
          do (release) ->
            for asset in release.assets when asset.state is 'uploaded' and minimatch asset.name, argv.filename
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
