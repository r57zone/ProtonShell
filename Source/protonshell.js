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

function appClose() {
	host("app.close");
}

function appFullscreen() {
	host("app.fullscreen");
}

function appRestore() {
	host("app.restore");
}

function appSetTitle(title) {
	host("app.setTitle", {"title": title});
}

function appOpen(path, args) {
	host("system.open", {"path": path, "args": args || ""});
}

function fileDelete(path, callback) {
	host("file.delete", {"path": path}, callback);
}

function fileExists(path, callback) {
	host("file.exists", {"path": path}, callback);
}

function fileWriteText(path, text, callback) {
	host("file.writeText", {"path": path, "text": text}, callback);
}

function fileReadText(path, callback) {
	host("file.readText", {"path": path}, callback);
}

function folderList(path, callback) {
	host("folder.list", {"path": path}, callback);
}

function folderExists(path, callback) {
	host("folder.exists", {"path": path}, callback);
}

function folderCreate(path, callback) {
	host("folder.create", {"path": path}, callback);
}

function folderDelete(path, callback) {
	host("folder.delete", {"path": path}, callback);
}

function clipboardGet(callback) {
	host("clipboard.get", {}, callback);
}

function clipboardSet(text, callback) {
	host("clipboard.set", {"text": text}, callback);
}

function dialogOpenFile(options, callback) {
	host("dialog.openFile", options || {}, callback);
}

function dialogSaveFile(options, callback) {
	host("dialog.saveFile", options || {}, callback);
}

function dialogSelectFolder(options, callback) {
	host("dialog.selectFolder", options || {}, callback);
}