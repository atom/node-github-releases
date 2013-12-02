minimatch = require 'minimatch'

# Returns whether the string {str} matches the filter {filter}.
matches = (str, filter) ->
  if filter instanceof RegExp
    filter.test str
  else
    minimatch str, filter

module.exports =
  class Filters
    @firstElementFilter: (value, i) ->
      i == 0

    @fieldMatchFilter: (filter, value) ->
      for k, v of filter
        return false unless value[k]? and matches value[k], v
      true
