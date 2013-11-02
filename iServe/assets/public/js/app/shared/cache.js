(function() {
	var MemoryCache = function() {
		this._cache = {};
		this.length = 0;
	};

	MemoryCache.prototype.get = function(name) {
		return this._cache[name] || null;
	};
	MemoryCache.prototype.set = function(name, obj) {
		if(obj === null || obj === undefined) return this.remove(name);

		if(!this._cache[name]) this.length++;
		this._cache[name] = JSON.parse(JSON.stringify(obj));
	};
	MemoryCache.prototype.remove = function(name) {
		if(this._cache[name]) this.length--;
		delete this._cache[name];
	};
	MemoryCache.prototype.key = function(i) {
		return _(this._cache).keys()[i] || null;
	};

	var ajax = Backbone.ajax;

	Backbone.ajax = function(options) {
		var url = options.url + '?' + $.param(options.data || {});
		var data = app.cache.get(url);
		var xhr;

		if(data && options.type.toUpperCase() === 'GET') {
			var request = new $.Deferred();
			xhr = request.promise();

			_(['abort', 'getAllResponseHeaders', 'getResponseHeader', 'overrideMimeType', 'setRequestHeader']).each(function(name) {
				xhr[name] = function() {};
			});

			if(options.beforeSend && options.beforeSend(xhr, options) === false) return xhr;

			xhr.readyState = 4;
			xhr.responseText = JSON.stringify(data);
			xhr.responseJSON = data;
			xhr.status = 200;
			xhr.statusText = 'OK';

			xhr.done(options.success);
			
			request.resolve(data, 'success', xhr);
		} else {
			app.cache.remove(url);

			xhr = ajax.apply(null, arguments);

			xhr.done(function(data, status, xhr) {
				app.cache.set(url, data);
			});
		}

		return xhr;
	};

	app.cache = new MemoryCache();
}());
