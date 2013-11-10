(function() {
	var noop = function() {};

	var FileView = app.views.TemplateView.extend({
		template: function() {
			return app.templates['file.html']({ file: this.model.attributes, album: this.options.album.attributes });
		},
		initialize: function() {
			this.state = 'ready';
		},
		loadThumbnail: function(callback) {
			callback = callback || noop;

			var $thumb = this.$('.thumbnail');
			var $image = this.$('.resource-thumbnail');

			var url = $image.attr('data-thumbnail');

			if(!url) {
				return callback();
			}

			var self = this;
			var img = new Image();
			var ondone = function(err) {
				$thumb
					.removeClass('loading')
					.addClass('loaded');

				self.state = err ? 'errored' : 'loaded';

				callback(err);
			};

			img.onload = function() {
				var container = { width: $image.innerWidth(), height: $image.innerHeight() };

				$(img)
					.css({ 
						width: img.width, 
						height: img.height,
						marginLeft: (container.width - img.width) * 0.5,
						marginTop: (container.height - img.height) * 0.25
					})
					.appendTo($image);

				ondone();
			};
			img.onerror = function() {
				ondone(new Error('Failed loading image'));
			};

			img.src = url;
			this.state = 'loading';

			$image.removeAttr('data-thumbnail');
		},
		isThumable: function() {
			return this.state === 'ready' && $.inviewport(this.$el, { threshold: 0 });
		}
	});

	var FileGridView = app.views.BaseView.extend({
		tagName: 'div',
		className: 'row',
		id: 'files-container',
		initialize: function() {
			this.listenTo(this.collection, 'add', this.renderFile);
			this.listenTo(this.collection, 'reset', this.renderAllFiles);

			var onDispatch;
			var queue = [];
			var available = 1;
			var dispatch = function() {
				if(available && queue.length) {
					available--;
					var file = queue.splice(0, 1)[0];

					file.loadThumbnail(function() {
						available++;
						dispatch();
					});
				}
			};
			var clear = function() {
				queue = [];
			};

			var $window = $(window);
			var self = this;

			$window.on('scroll resize', this._onViewportChange = function() {
				clearTimeout(onDispatch);
				onDispatch = setTimeout(function() {
					clear();

					_(self.subviews).each(function(file) {
						if(file.isThumable() && queue.indexOf(file) < 0) {
							queue.push(file);
						}
					});

					dispatch();
				}, 200);
			});

			this.on('remove', function() {
				$window.off('scroll resize', this._onViewportChange);
				clear();
			});
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

			this.subviews.push(view);
			this.$el.append(view.render().el);

			var self = this;

			clearTimeout(this._onLoadThumbnail);
			this._onLoadThumbnail = setTimeout(function() {
				self._onViewportChange();
			}, 10);
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
