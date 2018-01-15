'use strict';

var angular = require('angular');

angular
.module('loghouseApp')
.controller('SearchCtrl', ['$scope', '$stateParams', 'AppContextService', 'SearchApi',
  function($scope, $stateParams, AppContextService, SearchApi) {
    var vm = this;

    vm.appContext = AppContextService;
    vm.appContext.query_id = $stateParams.query_id;

    vm.query = {
      q: 'hello'
    };

    SearchApi.query({
      query_id: vm.appContext.query_id
    }).$promise.then(function(res){
      vm.entries = res;
    }, function(resp){
      vm.error = resp;
    });
  }
]);
