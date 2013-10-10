(function() {
	var FileView = app.views.BaseView.extend({
		template: _.template(app.templates['file.html']),
		render: function() {
			var file = this.template({ file: this.model.attributes, album: this.options.album.attributes });

			this.$el.remove();
			this.setElement(file);

			return this;
		}
	});

	var FileGridView = app.views.BaseView.extend({
		tagName: 'div',
		className: 'row',
		id: 'files-container',
		initialize: function() {
			this.listenTo(this.collection, 'add', this.renderFile);
			this.listenTo(this.collection, 'reset', this.renderAllFiles);
		},
		render: function() {
			this.renderAllFiles();
			return this;
		},
		renderAllFiles: function() {
			this.$el.empty();
			this.collection.each(this.renderFile, this);
		},
		renderFile: function(file) {
			var view = new FileView({ model: file, album: this.options.album });

			this.views.push(view);
			this.$el.append(view.render().el);
		}
	});

	var FilesHeaderView = app.views.BaseView.extend({
		template: _.template(app.templates['files-header.html']),
		render: function() {
			var header = this.template({ album: this.model.attributes });

			this.$el.remove();
			this.setElement(header);

			return this;
		}
	});

	var FilesShowView = app.views.BaseView.extend({
		template: _.template(app.templates['files-show.html']),
		render: function() {
			var file = this.template({ file: this.model.attributes });

			this.$el.remove();
			this.setElement(file);

			return this;
		}
	});

	app.views.FileView = FileView;
	app.views.FileGridView = FileGridView;
	app.views.FilesHeaderView = FilesHeaderView;
	app.views.FilesShowView = FilesShowView;
}());
