(function() {
	var albums = {
		index: function() {
			var albums = new app.models.AlbumCollection();

			albums.fetch({
				success: function() {
					var view = new app.views.AlbumGridView({ collection: albums });
					app.content.render(view.render().el);
				}
			});
		}
	};

	app.controllers.albums = albums;
}());
