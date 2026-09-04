window.addEventListener('contextmenu', function(event) {
    event.preventDefault();
    event.stopPropagation();
    window.chrome.webview.postMessage('{"id":1,"cmd":"app.close","data":{}}');
}, true);