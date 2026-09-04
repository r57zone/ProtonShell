[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/r57zone/ProtonShell/blob/master/README.md) 
[![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/r57zone/ProtonShell/blob/master/README.RU.md) 
← Choose language | Выберите язык

# ProtonShell
Lightweight wrapper for running websites and web applications based on Microsoft Edge (WebView2), with support for a native API.

ProtonShell allows you to run web content in separate windows, use custom JavaScript scripts, and interact with Windows through the API: work with files and folders, the clipboard, and system applications, open standard file and folder selection dialogs, and control the application window.

ProtonShell is suitable for creating standalone applications based on existing web services, as well as for running your own web applications. The Apps folder contains examples of ready-to-use applications.
 
## Screenshots
![](https://github.com/user-attachments/assets/902b2e58-664d-460f-abfd-37de3c8c920b)
[![](https://github.com/user-attachments/assets/3fb00a8e-e835-45fe-9fa6-46657f4c1e0b)](https://github.com/user-attachments/assets/08b09024-ff66-4e07-837c-5b4d918862d7)
[![](https://github.com/user-attachments/assets/c5f0d903-e7d4-42f3-91ad-38f7b6f08d4b)](https://github.com/user-attachments/assets/22419527-2937-4bdc-a7b8-95097cf25de7)
[![](https://github-production-user-asset-6210df.s3.amazonaws.com/9499881/258204596-0de84193-e560-4165-b104-69c5a0b63d34.jpg)](https://github.com/r57zone/ProtonShell/assets/9499881/6a2701eb-869e-480a-8548-628daec17fe7)
[![](https://github-production-user-asset-6210df.s3.amazonaws.com/9499881/258204442-90eb9ab6-d54b-4131-a8e8-12735213935f.jpg)](https://github.com/r57zone/ProtonShell/assets/9499881/e1ff8392-ba8b-4373-a20b-0d1a29773c10)
[![](https://github.com/user-attachments/assets/773978d5-e43c-4733-b05c-58fcad6c6a40)](https://github.com/user-attachments/assets/a4e77acb-1bfd-4fff-8e31-7415cd8b853a)
[![](https://github.com/user-attachments/assets/1c1a5637-6383-428a-8331-84656150f294)](https://github.com/user-attachments/assets/325c1c6d-8125-4f0a-beab-696e5fe7f19f)

## Setup
1. Install [Edge WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/).
2. Place the `index.html` file in the application folder or enter the URL address, in the configuration file.
3. Change the name, window parameters, icon, proxy, UserAgent and other settings, in the `Config.ini` configuration file.
4. If necessary, change the `exe` icon, using [Resource Hacker](http://www.angusj.com/resourcehacker/) or specify the icon in the configuration file.

## Download
>Version for Windows 10, 11.<br>

**[Download](https://github.com/r57zone/ProtonShell/releases)**

## Launch options
When using startup parameters, reading the configuration file is not used, except for the `-c` parameter (custom configuration file).

`-c anotherapp.ini` - read configuration file, with a different name. When used, other startup parameters are not used and all parameters are read from the configuration file.

`-f index.html` - the path to the html file (relative or full).

`-a "https://youtube.com/tv"` - the web site address.

`-n "My app"` - the title of the application.

`-i MyIcon.ico` - path to the icon.

`-u "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:131.0) Gecko/20100101 Firefox/131.0"` - user agent.

`-s 1.js` - user script (userscript).

`-w` - width of the application.

`-h` - height of the application.

`-fullscreen` - fullscreen mode.

`-p` - change system proxy to the specified one (format: IP:PORT).

`-rp` - return past system proxy, for cases of changing proxy to another one.

`-b 3` - frame style (None = `0`, Sizeable = `1`, Single = `2`, Dialog = 3, SizeToolWin = `4`, ToolWindow = `5`).

`-t 50` - indent from the top.

`-l 50` - indent to the right.

`-d` - enable debugging mode.

## Native API

First, include the ProtonShell API script in your HTML application:

```html
<script src="protonshell.js"></script>
```

All API functions are asynchronous and can accept a callback for the response.

### Application Control

| Command               | Description                                         | Parameters             |
| --------------------- | --------------------------------------------------- | ---------------------- |
| `app.close()`         | Closes the application window.                      | —                      |
| `app.fullscreen()`    | Switches the application window to fullscreen mode. | —                      |
| `app.restore()`       | Restores the normal window mode.                    | —                      |
| `app.setTitle(title)` | Changes the application window title.               | `title` — window title |

### System

| Command                   | Description                                                       | Parameters                                        |
| ------------------------- | ----------------------------------------------------------------- | ------------------------------------------------- |
| `system.open(path, args)` | Opens a file, folder, application or URL using the Windows shell. | `path` — path or URL; `args` — optional arguments |

### File Operations

| Command                      | Description                   | Parameters                        |
| ---------------------------- | ----------------------------- | --------------------------------- |
| `file.exists(path)`          | Checks whether a file exists. | `path` — file path                |
| `file.writeText(path, text)` | Writes text to a file.        | `path` — file path; `text` — text |
| `file.readText(path)`        | Reads text from a file.       | `path` — file path                |
| `file.delete(path)`          | Deletes a file.               | `path` — file path                |

### Folder Operations

| Command               | Description                                         | Parameters           |
| --------------------- | --------------------------------------------------- | -------------------- |
| `folder.list(path)`   | Returns a list of files and folders in a directory. | `path` — folder path |
| `folder.exists(path)` | Checks whether a folder exists.                     | `path` — folder path |
| `folder.create(path)` | Creates a folder.                                   | `path` — folder path |
| `folder.delete(path)` | Deletes an empty folder.                            | `path` — folder path |

### Clipboard

| Command               | Description                                          | Parameters    |
| --------------------- | ---------------------------------------------------- | ------------- |
| `clipboard.get()`     | Returns the current text from the Windows clipboard. | —             |
| `clipboard.set(text)` | Sets the Windows clipboard text.                     | `text` — text |

### Dialogs

| Command                        | Description                                         | Parameters                    |
| ------------------------------ | --------------------------------------------------- | ----------------------------- |
| `dialog.openFile(options)`     | Opens the standard Windows file selection dialog.   | `options` — optional settings |
| `dialog.saveFile(options)`     | Opens the standard Windows save file dialog.        | `options` — optional settings |
| `dialog.selectFolder(options)` | Opens the standard Windows folder selection dialog. | `options` — optional settings |

### Callbacks

Any API function can accept a callback as its last parameter:

```javascript
file.readText("test.txt", function(response) {
	alert(response);
});
```

The callback receives a JSON response from ProtonShell.

For detailed parameters, options and response formats, see the examples in `index.html`.

## Debug mode
For fast debugging you can enable a special mode in which the following is available: resizing, changing User agent, clearing all data. To enable it, change the `Debug` parameter to `1`.

[![](https://github.com/user-attachments/assets/c71837e8-9097-438f-8e15-93efc42b65d3)](https://github.com/user-attachments/assets/e2e88215-3e52-46dd-b24a-42eb6bfdc3e7)

## Feedback
`r57zone@gmail.com`