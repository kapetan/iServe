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

	app.Template.get(['album', 'file'], function(err, templates) {
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

		var AlbumView = Backbone.View.extend({
			/*events: {
				'click .thumbnail': 'files'
			},*/
			render: function() {
				var album = templates[0].render({ album: this.model.attributes });
				this.setElement(album);

				return this.$el;
			}
			/*,
			files: function() {
				this.model.getFiles({
					success: function(files) {
						var filesView = new FileCollectionView({ collection: files });
						filesView.render();
					}
				});
			}*/
		});

		var AlbumCollectionView = Backbone.View.extend({
			tagName: 'div',
			className: 'row',
			id: 'albums-container',
			initialize: function() {
				//this.setElement('#albums-container');

				//this.listenTo(this.collection, 'reset', this.render);
				this.listenTo(this.collection, 'add', this.addAlbum);
			},
			render: function() {
				//this.$el.empty();
				this.$el.appendTo('#main-container');
				this.collection.each(this.addAlbum, this);
			},
			addAlbum: function(album) {
				var view = new AlbumView({ model: album });
				this.$el.append(view.render());
			}
		});

		var FileView = Backbone.View.extend({
			render: function() {
				var file = templates[1].render({ file: this.model.attributes });
				this.setElement(file);

				return this.$el;
			}
		});

		var FileCollectionView = Backbone.View.extend({
			tagName: 'div',
			className: 'row',
			id: 'files-container',
			initialize: function() {
				//this.setElement('#files-container');

				//this.listenTo(this.collection, 'reset', this.render);
				this.listenTo(this.collection, 'add', this.addFile);
			},
			render: function() {
				//this.$el.empty();
				this.$el.appendTo('#main-container');
				this.collection.each(this.addFile, this);
			},
			addFile: function(file) {
				var view = new FileView({ model: file });
				this.$el.append(view.render());
			}
		});

		app.views.Album = AlbumView;
		app.views.AlbumCollection = AlbumCollectionView;
		app.views.File = FileView;
		app.views.FileCollection = FileCollectionView;

		setTimeout(function() {
			if(err) return onready.reject(err);
			onready.resolve();
		}, 10);
	});
}());
