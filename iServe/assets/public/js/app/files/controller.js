(function() {
	var files = {
		index: function(album) {
			var albums = new app.models.AlbumCollection();
			var onalbum = function(album) {
				album.getFiles({
					success: function(files) {
						var view = new app.views.FileGridView({ collection: files });
						app.content.render(view.render().el);
					}
				});
			};

			albums.fetch({ 
				success: function() {
					onalbum(albums.get(album));
				} 
			});
		},
		show: function(album, file) {
			
		}
	};

	app.controllers.files = files;
}());
