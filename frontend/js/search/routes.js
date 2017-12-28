'use strict';

var angular = require('angular')

angular
.module('loghouseApp')
.config([ '$stateProvider',
  function ($stateProvider) {
    $stateProvider
    .state('base.search', {
      url: '/query?query_id',
      views: {
        '@base': {
          templateUrl: 'search/search.html',
          controller: 'SearchCtrl',
          controllerAs: 'vm'
        }
      }
    });
  }]
);
