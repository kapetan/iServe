(function() {
	var templates = {};
	var create = function(templates, result) {
		_(templates)
			.chain()
			.keys()
			.each(function(key) {
				var t = templates[key];

				if(_(t).isObject()) {
					templates[key] = {};
					return create(t, templates[key]);
				}

				t = _.template(t);

				var fn = function(obj) {
					obj = _({}).extend(app.helpers, obj);
					return t(obj);
				};

				result[key] = fn;
			});
	};

	create(window._templates, templates);

	app.templates = templates;
}());
