(function() {
	var albums = {
		index: function() {
			var albums = new app.models.AlbumCollection();

			albums.fetch({
				error: app.controllers.errors.resource,
				success: function() {
					var view = new app.views.AlbumGridView({ collection: albums });

					app.header.clear();
					app.content.render(view.render());
				}
			});
		}
	};

	app.controllers.albums = albums;
}());
