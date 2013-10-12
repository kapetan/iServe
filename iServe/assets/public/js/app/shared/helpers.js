(function() {
	var APP_BASE = '/app';
	var helpers = {};

	helpers.href = function() {
		var args = _(arguments)
			.chain()
			.toArray()
			.map(function(path) {
				path = path.replace(/(^\/)|(\/$)/g, '');
				path = $.trim(path);

				return encodeURIComponent(path);
			})
			.without('')
			.value();

		args.splice(0, 0, APP_BASE);

		return args.join('/');
	};
	helpers.h = function(string) {
		return _.escape(string);
	};

	app.helpers = helpers;
}());
