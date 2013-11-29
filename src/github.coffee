request = require 'request'

class GitHub
  repo: null
  token: null

  # Public: Creates a {GitHub} object for given {repo} with optional {token}.
  constructor: ({user, @repo, @token}) ->
    @repo = "#{user}/#{@repo}" if user?

  # Public: List all releases of the repo.
  getReleases: (callback) ->
    @callRepoApi 'releases', callback

  # Public: Find the release whose tag_name is {tag}.
  getReleaseOfTag: (tag, callback) ->
    @getReleases (error, releases) ->
      return callback(error) if error?

      for release in releases when release.tag_name is tag
        return callback null, release
      return callback(new Error("Cannot find release with tag_name of #{tag}"))

  # Public: Find the release's assets with tag_name {tag}.
  getAssetsOfTag: (tag, callback) ->
    @getReleaseOfTag (error, release) =>
      return callback(error) if error?
      @callRepoApi "releases/#{release.id}/assets", callback

  # Public: Get the latest release.
  getLatestRelease: (callback) ->
    @getReleases (error, releases) ->
      return callback(error) if error?
      callback null, releases[0]

  # Public: Download the {asset}.
  #
  # The {callback} would be called with the downloaded file's {ReadableStream}.
  downloadAsset: (asset, callback) ->
    @downloadAssetOfUrl asset.url, callback

  # Public: Download the asset of {url}.
  #
  # The {callback} would be called with the downloaded file's {ReadableStream}.
  downloadAssetOfUrl: (url, callback) ->
    inputStream = request @getDownloadOptions(url)
    inputStream.on 'response', (response) =>
      # Manually handle redirection so headers would not be sent for S3.
      if response.statusCode is 302
        return @downloadAssetOfUrl response.headers.location, callback
      else if response.statusCode isnt 200
        return callback new Error("Request failed with code #{response.statusCode}")

      callback null, response

  # Private: Call the repos API.
  callRepoApi: (path, callback) ->
    options =
      url: "https://api.github.com/repos/#{@repo}/#{path}"
      proxy: process.env.http_proxy || process.env.https_proxy
      headers:
        accept: 'application/vnd.github.manifold-preview'
        'user-agent': 'node-github-releases/0.1.0'

    # Set access token.
    options.headers.authorization = "token #{@token}" if @token?

    request options, (error, response, body) ->
      if not error?
        data = JSON.parse(body)
        error = new Error(data.message) if response.statusCode != 200
      callback(error, data)

  # Private: Get the options for downloading asset.
  getDownloadOptions: (url) ->
    # Only set headers for GitHub host, the url could also be a S3 link and
    # setting headers for it would make the request fail.
    headers =
      if require('url').parse(url).hostname is 'api.github.com'
        authorization: "token #{@token}"
        accept: 'application/octet-stream'
        'user-agent': 'node-github-releases/0.1.0'
      else
        {}

    options =
      url: url
      # Do not follow redirection automatically, we need to handle it carefully.
      followRedirect: false
      proxy: process.env.http_proxy || process.env.https_proxy
      headers: headers

module.exports = GitHub
