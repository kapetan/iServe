(function() {
	var ondone = function() {
		var albums = new app.models.AlbumCollection();
		var albumsView = new app.views.AlbumsCollection({ collection: albums });

		albums.fetch();
	};

	$.when(app.ready, app.load)
		.done(ondone)
		.fail(function(err) {
			alert(err.message);
		});
}());
