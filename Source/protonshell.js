var hostRequestId = 0;
var hostCallbacks = {};

function host(cmd, data, callback) {
	var id = ++hostRequestId;

	if (callback)
		hostCallbacks[id] = callback;

	window.chrome.webview.postMessage(JSON.stringify({
		"id": id,
		"cmd": cmd,
		"data": data || {}
	}));
}

function handleMessageFromHost(message) {
	var response;

	try {
		response = JSON.parse(message);
	} catch (e) {
		console.error("Invalid ProtonShell response:", message);
		return;
	}

	if (response.id && hostCallbacks[response.id]) {
		var callback = hostCallbacks[response.id];

		delete hostCallbacks[response.id];

		callback(response);
	}
}


// App
var app = {
	close: function() {
		host("app.close");
	},

	fullscreen: function() {
		host("app.fullscreen");
	},

	restore: function() {
		host("app.restore");
	},

	setTitle: function(title) {
		host("app.setTitle", {
			"title": title
		});
	}
};


// System

var system = {
	open: function(path, args) {
		host("system.open", {
			"path": path,
			"args": args || ""
		});
	}
};


// Files

var file = {
	delete: function(path, callback) {
		host("file.delete", {
			"path": path
		}, callback);
	},

	exists: function(path, callback) {
		host("file.exists", {
			"path": path
		}, callback);
	},

	writeText: function(path, text, callback) {
		host("file.writeText", {
			"path": path,
			"text": text
		}, callback);
	},

	readText: function(path, callback) {
		host("file.readText", {
			"path": path
		}, callback);
	}
};


// Folders

var folder = {
	list: function(path, callback) {
		host("folder.list", {
			"path": path
		}, callback);
	},

	exists: function(path, callback) {
		host("folder.exists", {
			"path": path
		}, callback);
	},

	create: function(path, callback) {
		host("folder.create", {
			"path": path
		}, callback);
	},

	delete: function(path, callback) {
		host("folder.delete", {
			"path": path
		}, callback);
	}
};


// Clipboard

var clipboard = {
	get: function(callback) {
		host("clipboard.get", {}, callback);
	},

	set: function(text, callback) {
		host("clipboard.set", {
			"text": text
		}, callback);
	}
};


// Dialogs

var dialog = {
	openFile: function(options, callback) {
		host("dialog.openFile", options || {}, callback);
	},

	saveFile: function(options, callback) {
		host("dialog.saveFile", options || {}, callback);
	},

	selectFolder: function(options, callback) {
		host("dialog.selectFolder", options || {}, callback);
	}
};