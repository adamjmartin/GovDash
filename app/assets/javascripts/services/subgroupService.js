angular.module('subgroupService', [])
    .factory('Subgroups', function($location, $http, $q, $rootScope) {
       
        var subgroup = {
            
            create: function(name, description, groupIds) {
                return $http.post('/api/subgroups', {subgroup: {name: name, description: description, group_ids: groupIds } })
                .then(function(response) {
                    console.log('Subgroup Created!');
                });
                
            },
            getAllSubgroups: function() {
				return $http.get('/api/subgroups').then(function(response) {
					subgroups = response;
					return subgroups;
				});
            },
            getSubgroupById: function(subgroupId) {
            	return $http.get('api/subgroups/' + subgroupId).then(function(response) {
					subgroup = response;
					return subgroup;
				});
            },
            update: function(subgroupId, name, description, groupIds) {
            	return $http.put('api/subgroups/' + subgroupId, {subgroup: {id: subgroupId, name: name, description: description, group_ids: groupIds } })
				.then(function(response) {
                    console.log('Subgroup Updated!');
                });
            }
            
        };
        return subgroup;
    });
