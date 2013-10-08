(function() {
	var File = Backbone.Model.extend({
		idAttribute: 'url'
	});

	var FileCollection = Backbone.Collection.extend({
		model: File,
		url: '/api/files'
	});

	app.models.File = File;
	app.models.FileCollection = FileCollection;
}());
