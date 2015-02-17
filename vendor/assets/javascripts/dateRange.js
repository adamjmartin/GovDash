'use strict';

var Module = angular.module('datePicker');

Module.directive('dateRange', function () {
  return {
    templateUrl: 'template/daterange.html',
    scope: {
      start: '=',
      end: '='
    },
    link: function (scope, element, attrs) {
      attrs.$observe('disabled', function(isDisabled){
          scope.disableDatePickers = !!isDisabled;
        });
      scope.$watch('start.getTime()', function (value) {
        if (value && scope.end && value > scope.end.getTime()) {
          scope.end = new Date(value);
        }
      });
      scope.$watch('end.getTime()', function (value) {
        if (value && scope.start && value < scope.start.getTime()) {
          scope.start = new Date(value);
        }
      });
    }
  };
});
