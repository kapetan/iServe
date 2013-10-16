(function() {
	var fetchAlbum = function(id, callback) {
		var albums = new app.models.AlbumCollection();
		var onalbum = function(album) {
			if(!album) {
				var err = new Error('Album not found');
				app.controllers.errors.notFound(err);

				return;
			}

			album.getFiles({
				error: app.controllers.errors.resource,
				success: function(files) {
					callback(album, files);
				}
			});
		};

		albums.fetch({ 
			error: app.controllers.errors.resource,
			success: function() {
				onalbum(albums.get(id));
			} 
		});
	};

	var files = {
		index: function(album) {
			fetchAlbum(album, function(album, files) {
				var header = new app.views.FilesHeaderView({ model: album });
				var view = new app.views.FileGridView({ collection: files, album: album });

				app.header.render(header.render());
				app.content.render(view.render());
			});
		},
		show: function(album, file) {
			fetchAlbum(album, function(album, files) {
				file = files.get(file);

				var current = files.indexOf(file);

				var header = new app.views.FilesShowHeaderView({ album: album, collection: files, current: current });
				var view = new app.views.FilesShowView({ model: file });

				app.header.render(header.render());
				app.content.render(view.render());
			});
		}
	};

	app.controllers.files = files;
}());
