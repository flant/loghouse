'use strict';

var angular = require('angular');

angular
.module('loghouseApp')
.factory('SearchApi', [ '$resource',
  function($resource) {
    var QueriesApi = $resource("/api/search", {}, {
      query:  { method: 'GET', isArray: true }
    });

    return QueriesApi;
  }
]);
