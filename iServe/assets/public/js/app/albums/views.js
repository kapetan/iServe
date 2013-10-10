(function() {
	var AlbumView = app.views.BaseView.extend({
		template: _.template(app.templates['album.html']),
		render: function() {
			var album = this.template({ album: this.model.attributes });

			this.$el.remove();
			this.setElement(album);

			return this;
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
