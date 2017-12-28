'use strict'

var angular = require('angular');

angular
.module('loghouseApp')
.controller('NavigationCtrl', ['$scope', '$state', 'QueriesApi',
  function($scope, $state, QueriesApi) {
    var vm = this;

    vm.state = $state.current.name
    vm.queries = QueriesApi.query();
  }
]);
