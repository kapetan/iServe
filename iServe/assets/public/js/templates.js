(function() {
	var cache = {};

	var get = function(path, callback) {
		if(!/\.html$/.test(path)) {
			path = path + '.html';
		}

		if(cache[path]) {
			return callback(null, cache[path]);
		}

		$.ajax('/public/templates/' + path, {
			type: 'GET',
			dataType: 'html',
			success: function(response) {
				callback(null, cache[path] = new Template(response));
			},
			error: function() {
				callback(new Error('Error fetching template'));
			}
		});
	};

	var Template = function(content) {
		this._content = (typeof content === 'function') ? content : _.template(content);
	};

	Template.get = function(path, callback) {
		if(!_(path).isArray()) {
			return get(path, callback);
		}

		callback = _(callback).once();

		var count = path.length;
		var result = [];

		_(path).forEach(function(p, i) {
			get(p, function(err, template) {
				if(err) return callback(err);

				result[i] = template;

				if(!--count) {
					callback(null, result);
				}
			});
		});
	};

	Template.prototype.render = function(locals, callback) {
		return this._content(locals || {});
	};

	app.Template = Template;
}());
