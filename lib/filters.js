(function() {
  var Filters, minimatch;

  minimatch = require('minimatch');

  module.exports = Filters = (function() {
    function Filters() {}

    Filters.prototype.filter = function(array, filter) {
      if (!(filter instanceof Function)) {
        filter = this.fieldMatchFilter.bind(this, filter);
      }
      return array.filter(filter);
    };

    Filters.prototype.matches = function(str, filter) {
      var _i, _len, _ref;
      if (filter instanceof RegExp) {
        return filter.test(str);
      } else {
        _ref = filter.split(',');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          filter = _ref[_i];
          if (minimatch(str, filter)) {
            return true;
          }
        }
        return false;
      }
    };

    Filters.prototype.fieldMatchFilter = function(filter, value) {
      var k, v;
      for (k in filter) {
        v = filter[k];
        if (!((value[k] != null) && this.matches(value[k], v))) {
          return false;
        }
      }
      return true;
    };

    return Filters;

  })();

}).call(this);
