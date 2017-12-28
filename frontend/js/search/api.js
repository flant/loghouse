'use strict';

var angular = require('angular');

angular.module('loghouseApp').factory('SearchApi', [ '$resource',
  function($resource) {
    var QueriesApi = $resource("/api/queries/:identifier/:method", {}, {
      query:  { method: 'GET', isArray: true },
      save:   { method: 'POST' },
      update: { method: 'PUT', params: { identifier: '@uuid' } },
      get:    { method: 'GET', params: { identifier: "@uuid", method: 'show'} },
      new:    { method: 'GET', params: { method: 'new' } },
      edit:   { method: 'GET', params: { identifier: "@uuid", method: 'edit' } },
      delete: { method: 'DELETE', params: { identifier: "@uuid" } }
    });

    return QueriesApi;
  }
]);
