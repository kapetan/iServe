(function() {
	var FileView = app.views.TemplateView.extend({
		template: function() {
			return app.templates['file.html']({ file: this.model.attributes, album: this.options.album.attributes });
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

	var FilesHeaderView = app.views.TemplateView.extend({
		template: function() {
			return app.templates['files-header.html']({ album: this.model.attributes });
		}
	});

	var FilesShowView = app.views.TemplateView.extend({
		template: function() {
			return app.templates['files-show.html']({ file: this.model.attributes });
		}
	});

	var FilesShowHeaderView = app.views.TemplateView.extend({
		template: function() {
			var first = this.options.current === 0;
			var last = this.options.current === this.collection.length - 1;

			return app.templates['files-show-header.html']({ 
				album: this.options.album.attributes, 
				files: this.collection.toJSON(), 
				current: this.options.current,
				first: first,
				last: last
			});
		}
	});

	app.views.FileView = FileView;
	app.views.FileGridView = FileGridView;
	app.views.FilesHeaderView = FilesHeaderView;
	app.views.FilesShowView = FilesShowView;
	app.views.FilesShowHeaderView = FilesShowHeaderView;
}());
