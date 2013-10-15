(function() {
	var HTTP_STATUS_CODES = {
		403: 'forbidden',
		404: 'notFound',
		500: 'internalServerError'
	};

	var errors = function(err, options) {
		options = options || {};

		err.statusCode = err.statusCode || options.statusCode || 500;
		err.statusMessage = err.statusMessage || options.statusMessage || HTTP_STATUS_CODES[err.statusCode];

		var fn = errors[err.statusMessage] || errors.all;

		fn(err);
	};

	errors.notFound = function(err) {
		errors.all(err);
	};
	errors.forbidden = function(err) {
		errors.all(err);
	};
	errors.all = function(err) {
		var view = new app.views.ErrorView({ error: err });
		
		app.header.clear();
		app.content.render(view.render());
	};

	errors.resource = function(model, response) {
		var message = (response.responseJSON && response.responseJSON.message) || response.responseText;
		var err = new Error(message + ' (' + response.status + ' ' + response.statusText + ')');

		errors(err, { statusCode: response.status });
	};

	app.controllers.errors = errors;
}());
