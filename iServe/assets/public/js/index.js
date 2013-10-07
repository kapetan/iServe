(function() {
	var ApplicationRouter = Backbone.Router.extend({
		initialize: function() {
			this._albums = new app.models.AlbumCollection();
			this._view = null;
		},
		routes: {
			'': 'albums',
			'albums/:album': 'files'
		},
		albums: function() {
			this.clear();

			var albumsView = this._view = new app.views.AlbumCollection({ collection: this._albums });

			albumsView.render();
			this._albums.fetch();
		},
		files: function(albumUrl) {
			this.clear();

			var self = this;
			var album = this._albums.get(albumUrl);

			var onalbum = function(album) {
				album.getFiles({
					success: function(files) {
						var filesView = self._view = new app.views.FileCollection({ collection: files });
						filesView.render();
					}
				});
			};

			if(album) {
				return onalbum(album);
			}

			this._albums.fetch({ 
				success: function(albums) {
					onalbum(albums.get(albumUrl));
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
