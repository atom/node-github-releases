request = require 'request'
Filters = require './filters'

class GitHub extends Filters
  repo: null
  token: null

  # Public: Creates a {GitHub} object for given {repo} with optional {token}.
  constructor: ({user, @repo, @token}) ->
    @repo = "#{user}/#{@repo}" if user?

  # Public: List all releases of the repo which matches the {filter}.
  getReleases: (filter, callback) ->
    [callback, filter] = [filter, {}] if not callback? and filter instanceof Function

    @callRepoApi 'releases', (error, releases) =>
      return callback(error) if error?
      callback null, @filter(releases, filter)

  # Public: Download the {asset}.
  #
  # The {callback} would be called with the downloaded file's {ReadableStream}.
  downloadAsset: (asset, callback) ->
    @downloadAssetOfUrl asset.url, callback

  # Private: Download the asset of {url}.
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
        accept: 'application/octet-stream'
        'user-agent': 'node-github-releases/0.1.0'
      else
        {}

    # Set access token.
    headers.authorization = "token #{@token}" if @token?

    options =
      url: url
      # Do not follow redirection automatically, we need to handle it carefully.
      followRedirect: false
      proxy: process.env.http_proxy || process.env.https_proxy
      headers: headers

  # Private: Filter the array with {filter} if {filter} is a function, otherwise
  #          filter the array with elements that match the {filter}.
  filter: (array, filter) ->
    filter = @constructor.fieldMatchFilter.bind array, filter unless filter instanceof Function
    array.filter filter

module.exports = GitHub
