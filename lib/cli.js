(function() {
  var GitHub, argv, command, fs, github, minimatch, optimist, options, prettyjson, print, run;

  fs = require('fs');

  optimist = require('optimist');

  prettyjson = require('prettyjson');

  minimatch = require('minimatch');

  GitHub = require('../lib/github');

  options = optimist.usage("Usage: github-releases [--tag==<tag>] [--filename=<filename>] [--token=<token>] <command> <repo>").alias('h', 'help').describe('help', 'Print this usage message').string('token').describe('token', 'Your GitHub token').string('tag').describe('tag', 'The tag of the release')["default"]('tag', '*').string('filename').describe('filename', 'The filename of the asset')["default"]('filename', '*');

  print = function(error, result) {
    var message, _ref;
    if (error != null) {
      message = (_ref = error.message) != null ? _ref : error;
      return console.error("Command failed with error: " + message);
    } else {
      return console.log(prettyjson.render(result));
    }
  };

  run = function(github, command, argv, callback) {
    switch (command) {
      case 'list':
        return github.getReleases({
          tag_name: argv.tag
        }, callback);
      case 'show':
        return run(github, 'list', argv, function(error, releases) {
          if (error != null) {
            return callback(error);
          }
          if (releases.length === 0) {
            return callback(new Error("No matching release can be found"));
          }
          return callback(null, releases[0]);
        });
      case 'download':
        return run(github, 'show', argv, function(error, release) {
          var asset, _i, _len, _ref, _results;
          if (error != null) {
            return callback(error);
          }
          _ref = release.assets;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            asset = _ref[_i];
            if (asset.state === 'uploaded' && minimatch(asset.name, argv.filename)) {
              _results.push((function(asset) {
                return github.downloadAsset(asset, function(error, stream) {
                  if (error != null) {
                    return console.error("Unable to download " + asset.name);
                  }
                  return stream.pipe(fs.createWriteStream(asset.name));
                });
              })(asset));
            }
          }
          return _results;
        });
      case 'download-all':
        return run(github, 'list', argv, function(error, releases) {
          var release, _i, _len, _results;
          if (error != null) {
            return callback(error);
          }
          _results = [];
          for (_i = 0, _len = releases.length; _i < _len; _i++) {
            release = releases[_i];
            _results.push((function(release) {
              var asset, _j, _len1, _ref, _results1;
              _ref = release.assets;
              _results1 = [];
              for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
                asset = _ref[_j];
                if (asset.state === 'uploaded' && minimatch(asset.name, argv.filename)) {
                  _results1.push((function(asset) {
                    return github.downloadAsset(asset, function(error, stream) {
                      if (error != null) {
                        return console.error("Unable to download " + asset.name);
                      }
                      return stream.pipe(fs.createWriteStream(asset.name));
                    });
                  })(asset));
                }
              }
              return _results1;
            })(release));
          }
          return _results;
        });
      default:
        return console.error("Invalid command: " + command);
    }
  };

  argv = options.argv;

  if (argv._.length < 2 || argv.h) {
    return options.showHelp();
  }

  command = argv._[0];

  github = new GitHub({
    repo: argv._[1],
    token: argv.token
  });

  run(github, command, argv, print);

}).call(this);
