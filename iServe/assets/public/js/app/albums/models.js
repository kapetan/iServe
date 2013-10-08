(function() {
	var Album = Backbone.Model.extend({
		idAttribute: 'url',

		getFiles: function(options) {
			options = options || {};
			var data = options.data || {};

			data.album = this.get('url');
			options.data = data;

			var files = new app.models.FileCollection();
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
