'use strict';

var angular = require('angular');

angular
.module('loghouseApp')
.directive('lhFilterForm', [
  function () {
    return {
      restrict: 'E',
      scope: {
        query: '=',
        appContext: '<'
      },
      // link: function(scope, element, attrs) {
      // },
      templateUrl: 'search/_filter_form.html'
    }
  }
])
