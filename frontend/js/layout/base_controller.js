'use strict'

var angular = require('angular');

angular
.module('loghouseApp')
.controller('BaseCtrl', ['$scope', function($scope) {
  var base_vm = this;
  base_vm.version = window.appVersion;
  base_vm.currentUser = window.currentUser;
}]);
