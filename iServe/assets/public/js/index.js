(function() {
	var ApplicationRouter = Backbone.Router.extend({
		initialize: function() {
			this._albums = new app.models.AlbumCollection();
			this._view = null;
		},
		routes: {
			'': 'albums',
			'files/:album': 'files'
		},
		albums: function() {
			this.clear();

			var albumsView = this._view = new app.views.AlbumCollection({ collection: this._albums });

			albumsView.render();
			this._albums.fetch();
		},
		files: function(album) {
			this.clear();

			var self = this;
			album = this._albums.get(album);

			album.getFiles({
				success: function(files) {
					var filesView = self._view = new app.views.FileCollection({ collection: files });
					filesView.render();
				}
			});
		},
		clear: function() {
			if(this._view) this._view.remove();
		}
	});

	$.when(app.ready, app.load)
		.done(function() {
			new ApplicationRouter();
			Backbone.history.start({ root: '/public/index.html' });
		})
		.fail(function(err) {
			alert(err.message);
		});
}());
