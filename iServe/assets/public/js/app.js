(function() {
	app.models = {};
	app.views = {};

	var onready = new $.Deferred();
	var onload = new $.Deferred();

	app.ready = onready.promise();
	app.load = onload.promise();

	$(function() {
		onload.resolve();
	});

	app.Template.get(['album'], function(err, templates) {
		var Album = Backbone.Model.extend({
			idAttribute: 'url',

			getFiles: function(options) {
				options = options || {};
				var data = options.data || {};

				data.album = this.get('url');
				options.data = data;

				var files = new FileCollection();
				files.fetch(options);
			}
		});

		var AlbumCollection = Backbone.Collection.extend({
			model: Album,
			url: '/albums'
		});

		var File = Backbone.Model.extend({
			idAttribute: 'url'
		});

		var FileCollection = Backbone.Collection.extend({
			model: File,
			url: '/files'
		});

		app.models.Album = Album;
		app.models.AlbumCollection = AlbumCollection;
		app.models.File = File;
		app.models.FileCollection = FileCollection;

		var AlbumsView = Backbone.View.extend({
			render: function() {
				var albums = templates[0].render({ album: this.model.attributes });
				this.setElement(albums);

				return this.$el;
			}
		});

		var AlbumsCollectionView = Backbone.View.extend({
			initialize: function() {
				this.setElement('#albums-container');

				this.listenTo(this.collection, 'reset', this.render);
				this.listenTo(this.collection, 'add', this.addAlbum);
			},
			render: function() {
				this.$el.empty();
				this.collection.each(this.addAlbum);
			},
			addAlbum: function(album) {
				var view = new AlbumsView({ model: album });
				this.$el.append(view.render());
			}
		});

		app.views.Albums = AlbumsView;
		app.views.AlbumsCollection = AlbumsCollectionView;

		setTimeout(function() {
			if(err) return onready.reject(err);
			onready.resolve();
		}, 10);
	});
}());
