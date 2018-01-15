'use strict'

var angular = require('angular');

angular
.module('loghouseApp')
.controller('NavigationCtrl', ['$scope', '$state', 'QueriesApi', 'AppContextService',
  function($scope, $state, QueriesApi, AppContextService) {
    var vm = this;

    vm.appContext = AppContextService;
    vm.state = $state.current.name;
    vm.queries = QueriesApi.query();
  }
]);
