(function() {
	var ApplicationRouter = Backbone.Router.extend({
		routes: {
			'app(/)': 'root',
			'app/albums(/)': 'albums',
			'app/files/:album(/)': 'files',
			'app/files/:album/:file(/)': 'file'
		},
		root: function() {
			window.location.href = '/app/albums';
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
