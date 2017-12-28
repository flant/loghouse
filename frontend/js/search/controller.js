'use strict'

var angular = require('angular');

angular
.module('loghouseApp')
.controller('SearchCtrl', ['$scope', '$stateParams',
  function($scope, $stateParams) {
    var vm = this;
    console.log('QUEYR_ID', $scope);
    vm.query_id = $scope.$parent.query_id = $stateParams.query_id;
  }
]);
