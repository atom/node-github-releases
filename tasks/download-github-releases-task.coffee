fs        = require 'fs'
path      = require 'path'
os        = require 'os'
minimatch = require 'minimatch'
GitHub    = require '../lib/github'

module.exports = (grunt) ->
  taskName = 'download-github-releases'
  grunt.registerTask taskName, 'Download assets from GitHub Releases', ->
    done = @async()

    config = grunt.config taskName
    unless config.repo?
      grunt.log.error 'Repo must be specified'

    tag = config.tag ? '*'
    filename = config.filename ? '*'
    outputDir = config.outputDir ? os.tmpdir()

    github = new GitHub(config)
    github.getReleases tag_name: tag, (error, releases) ->
      if error?
        grunt.log.error 'Failed to get releases', error
        return done false

      if releases.length < 0
        grunt.log.error 'No specified releases is found'
        return done false

      count = 0
      completed = 0
      files = []
      downloadDone = ->
        ++completed
        if count is completed
          grunt.config "#{taskName}.files", files
          done true

      for release in releases
        do (release) ->
          for asset in release.assets
            do (asset) ->
              if minimatch asset.name, filename
                ++count
                github.downloadAsset asset, (error, inputStream) ->
                  outputPath = path.join outputDir, asset.name
                  inputStream.pipe fs.createWriteStream(outputPath)
                  inputStream.on 'error', ->
                    grunt.log.error 'Failed to download', asset.name
                    downloadDone()
                  inputStream.on 'end', ->
                    files.push outputPath
                    downloadDone()

      if count is 0
        grunt.log.error 'No matching asset is found'
        done false
