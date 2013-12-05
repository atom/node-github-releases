minimatch = require 'minimatch'

module.exports =
  class Filters
    # Protected: Filter the array with {filter} if {filter} is a function,
    #            otherwise filter the array with elements that match the
    #            {filter}.
    filter: (array, filter) ->
      filter = @fieldMatchFilter.bind this, filter unless filter instanceof Function
      array.filter filter

    # Private: Returns whether the string {str} matches the filter {filter}.
    matches: (str, filter) ->
      if filter instanceof RegExp
        filter.test str
      else
        for filter in filter.split ','
          return true if minimatch str, filter
        false

    # Private: Helper filter to test if {value} matches the {filter}
    fieldMatchFilter: (filter, value) ->
      for k, v of filter
        return false unless value[k]? and @matches value[k], v
      true
