minimatch = require 'minimatch'

module.exports =
  class Filters
    @firstElementFilter: (value, i) ->
      i == 0

    @fieldMatchFilter: (filter, value) ->
      for k, v of filter
        return false unless value[k]? and minimatch value[k], v
      true
