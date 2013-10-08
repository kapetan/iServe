(function() {
	var FileView = Backbone.View.extend({
		template: _.template(app.templates['file.html']),
		render: function() {
			var file = this.template({ file: this.model.attributes });
			this.setElement(file);

			return this;
		}
	});

	var FileGridView = Backbone.View.extend({
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
			this.collection.each(this.renderFile, this);
		},
		renderFile: function(file) {
			var view = new FileView({ model: file });
			this.$el.append(view.render().el);
		}
	});

	app.views.FileView = FileView;
	app.views.FileGridView = FileGridView;
}());
