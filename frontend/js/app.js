'use strict';

var angular = require('angular');
require ('@uirouter/angularjs/release/angular-ui-router');
require ('angular-resource');
require ('ui-select');

// require('./main');
require ('../templates/layout');

var app = angular.module('loghouseApp', [
  'ui.router',
  'ui.select',
  'ngResource',
  'templates'
])

require ('./app_context_service');
require ('./layout');
require ('./search');
require ('./queries');

app.config(['$stateProvider', '$locationProvider', '$urlRouterProvider', function($stateProvider, $locationProvider, $urlRouterProvider) {
  $locationProvider.html5Mode(true);

  $urlRouterProvider.otherwise('/query');
  // HACK for root state aliases: "/state", "/state/", "/"
  // $urlRouterProvider.when(/^\/?$/, ['$match', '$state', function($match, $state){
  //   $state.go('base', {}, {location: false})
  //   return true;
  // }]);

  $stateProvider
  .state('base', {
    url: '',
    views: {
      '@': {
        controller: 'BaseCtrl',
        controllerAs: 'base_vm',
        templateUrl: 'layout/base.html'
      },
      'nav@base': {
        controller: 'NavigationCtrl',
        controllerAs: 'nav_vm',
        templateUrl: 'layout/_navigation.html'
      }
    }
  });
}]);
