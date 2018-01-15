'use strict'

var angular = require('angular');

angular
.module('loghouseApp')
.controller('BaseCtrl', ['$scope', 'AppContextService',
  function($scope, AppContextService) {
    var vm = this;

    vm.appContext = AppContextService;
  }
]);
