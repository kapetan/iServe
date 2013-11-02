(function() {
	var Album = Backbone.Model.extend({
		idAttribute: 'url',
		getFiles: function(options) {
			var files = new app.models.FileCollection(null, { album: this });
			files.fetch(options);
		}
	});

	var AlbumCollection = Backbone.Collection.extend({
		model: Album,
		url: '/api/albums'
	});

	app.models.Album = Album;
	app.models.AlbumCollection = AlbumCollection;
}());
