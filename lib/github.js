(function() {
  var Filters, GitHub, request,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  request = require('request');

  Filters = require('./filters');

  GitHub = (function(_super) {
    __extends(GitHub, _super);

    GitHub.prototype.repo = null;

    GitHub.prototype.token = null;

    function GitHub(_arg) {
      var user;
      user = _arg.user, this.repo = _arg.repo, this.token = _arg.token;
      if (user != null) {
        this.repo = "" + user + "/" + this.repo;
      }
    }

    GitHub.prototype.getReleases = function(filter, callback) {
      var responseIsArray, urlPath, _ref,
        _this = this;
      if ((callback == null) && filter instanceof Function) {
        _ref = [filter, {}], callback = _ref[0], filter = _ref[1];
      }
      urlPath = 'releases';
      responseIsArray = true;
      if (filter.tag_name != null) {
        urlPath += "/tags/" + filter.tag_name;
        responseIsArray = false;
      }
      return this.callRepoApi(urlPath, function(error, releases) {
        if (error != null) {
          return callback(error);
        }
        if (!responseIsArray) {
          releases = [releases];
        }
        return callback(null, _this.filter(releases, filter));
      });
    };

    GitHub.prototype.downloadAsset = function(asset, callback) {
      return this.downloadAssetOfUrl(asset.url, callback);
    };

    GitHub.prototype.downloadAssetOfUrl = function(url, callback) {
      var inputStream,
        _this = this;
      inputStream = request(this.getDownloadOptions(url));
      return inputStream.on('response', function(response) {
        if (response.statusCode === 302) {
          return _this.downloadAssetOfUrl(response.headers.location, callback);
        } else if (response.statusCode !== 200) {
          return callback(new Error("Request failed with code " + response.statusCode));
        }
        return callback(null, response);
      });
    };

    GitHub.prototype.callRepoApi = function(path, callback) {
      var options;
      options = {
        url: "https://api.github.com/repos/" + this.repo + "/" + path,
        proxy: process.env.http_proxy || process.env.https_proxy,
        headers: {
          accept: 'application/vnd.github.manifold-preview',
          'user-agent': 'node-github-releases/0.1.0'
        }
      };
      if (this.token != null) {
        options.headers.authorization = "token " + this.token;
      }
      return request(options, function(error, response, body) {
        var data;
        if (error == null) {
          data = JSON.parse(body);
          if (response.statusCode !== 200) {
            error = new Error(data.message);
          }
        }
        return callback(error, data);
      });
    };

    GitHub.prototype.getDownloadOptions = function(url) {
      var headers, isGitHubUrl, options;
      isGitHubUrl = require('url').parse(url).hostname === 'api.github.com';
      headers = isGitHubUrl ? {
        accept: 'application/octet-stream',
        'user-agent': 'node-github-releases/0.1.0'
      } : {};
      if (isGitHubUrl && (this.token != null)) {
        headers.authorization = "token " + this.token;
      }
      return options = {
        url: url,
        followRedirect: false,
        proxy: process.env.http_proxy || process.env.https_proxy,
        headers: headers
      };
    };

    return GitHub;

  })(Filters);

  module.exports = GitHub;

}).call(this);
