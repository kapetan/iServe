(function() {
	var ApplicationRouter = Backbone.Router.extend({
		initialize: function() {
			this._albums = new app.models.AlbumCollection();
			this._view = null;
		},
		routes: {
			'albums': 'albums',
			'files/:album': 'files',
			'files/:album/:file': 'file'
		},
		albums: function() {
			app.controllers.albums.index();
		},
		files: function(album) {
			app.controllers.files.index(album);
		},
		file: function(album, file) {
			app.controllers.files.show(album, file);
		}
	});

	app.router = new ApplicationRouter();
}());
