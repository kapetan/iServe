(function() {
	var File = Backbone.Model.extend({
		idAttribute: 'url'
	});

	var FileCollection = Backbone.Collection.extend({
		model: File,
		initialize: function(models, options) {
			this.album = options.album;
		},
		url: function() {
			return '/api/files?' + $.param({ album: this.album.id });
		}
	});

	app.models.File = File;
	app.models.FileCollection = FileCollection;
}());
