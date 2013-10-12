(function() {
	var AlbumView = app.views.TemplateView.extend({
		template: function() {
			return app.templates['album.html']({ album: this.model.attributes });
		}
	});

	var AlbumGridView = app.views.BaseView.extend({
		tagName: 'div',
		className: 'row',
		id: 'albums-container',
		initialize: function() {
			this.listenTo(this.collection, 'add', this.renderAlbum);
			this.listenTo(this.collection, 'reset', this.renderAllAlbums);
		},
		render: function() {
			this.renderAllAlbums();
			return this;
		},
		renderAllAlbums: function() {
			this.$el.empty();
			this.collection.each(this.renderAlbum, this);
		},
		renderAlbum: function(album) {
			var view = new AlbumView({ model: album });

			this.views.push(view);
			this.$el.append(view.render().el);
		}
	});

	app.views.AlbumView = AlbumView;
	app.views.AlbumGridView = AlbumGridView;
}());
