(function() {
	var fetchAlbum = function(id, callback) {
		var albums = new app.models.AlbumCollection();
		var onalbum = function(album) {
			album.getFiles({
				success: function(files) {
					callback(album, files);
				}
			});
		};

		albums.fetch({ 
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

			/*var albums = new app.models.AlbumCollection();
			var onalbum = function(album) {
				album.getFiles({
					success: function(files) {
						var header = new app.views.FilesHeaderView({ model: album });
						var view = new app.views.FileGridView({ collection: files });

						app.header.render(header.render());
						app.content.render(view.render());
					}
				});
			};

			albums.fetch({ 
				success: function() {
					onalbum(albums.get(album));
				} 
			});*/
		},
		show: function(album, file) {
			fetchAlbum(album, function(album, files) {
				file = files.get(file);
				var view = new app.views.FilesShowView({ model: file });

				app.header.clear();
				app.content.render(view.render());
			});
		}
	};

	app.controllers.files = files;
}());
