'use strict';

var angular = require('angular');

angular
.module('loghouseApp')
.factory('AppContextService', ['$window',
  function($window){
    return $window.appContext;
  }
]);
