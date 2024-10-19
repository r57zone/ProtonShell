[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/r57zone/ProtonShell/blob/master/README.md) 
[![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/r57zone/ProtonShell/blob/master/README.RU.md) 
# ProtonShell
Легковесная оболочка для веб-сайтов, простых веб-приложений, работающая на базе системного браузера Microsoft Edge. На её основе можно сделать отдельное окно для сайтов, например, для: YouTube (TV), Google Docs, ChatGPT, чата Twitch, Инстаграмма, с пользовательским js скриптом или какое-то веб-приложение в своём окне. В папке `Apps` можно найти готовые параметры запуска для YouTube TV, ChatGPT, Discord, Instagram, чата Twitch, клиента X, а также простую оболочку для запуска других приложений. 

## Скриншоты
![](https://github.com/user-attachments/assets/902b2e58-664d-460f-abfd-37de3c8c920b)
[![](https://github.com/user-attachments/assets/3fb00a8e-e835-45fe-9fa6-46657f4c1e0b)](https://github.com/user-attachments/assets/08b09024-ff66-4e07-837c-5b4d918862d7)
[![](https://github.com/user-attachments/assets/c5f0d903-e7d4-42f3-91ad-38f7b6f08d4b)](https://github.com/user-attachments/assets/22419527-2937-4bdc-a7b8-95097cf25de7)
[![](https://github-production-user-asset-6210df.s3.amazonaws.com/9499881/258204596-0de84193-e560-4165-b104-69c5a0b63d34.jpg)](https://github.com/r57zone/ProtonShell/assets/9499881/6a2701eb-869e-480a-8548-628daec17fe7)
[![](https://github-production-user-asset-6210df.s3.amazonaws.com/9499881/258204442-90eb9ab6-d54b-4131-a8e8-12735213935f.jpg)](https://github.com/r57zone/ProtonShell/assets/9499881/e1ff8392-ba8b-4373-a20b-0d1a29773c10)
[![](https://github.com/user-attachments/assets/773978d5-e43c-4733-b05c-58fcad6c6a40)](https://github.com/user-attachments/assets/a4e77acb-1bfd-4fff-8e31-7415cd8b853a)
[![](https://github.com/user-attachments/assets/1c1a5637-6383-428a-8331-84656150f294)](https://github.com/user-attachments/assets/325c1c6d-8125-4f0a-beab-696e5fe7f19f)

## Настройка
1. Установите [Edge WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/).
2. Поместите файл `index.html` в папку с приложением или введите URL адрес, в конфигурационный файл.
3. Измените название, параметры окна, иконку, прокси, UserAgent и другие настройки, в конфигурационном файле `Config.ini`.
4. При необходимости измените иконку `exe`, с помощью [Resource Hacker](http://www.angusj.com/resourcehacker/) или укажите иконку в конфигурационном файле.

## Параметры запуска
При использовании параметров запуска чтение конфигурационного файла не используется, исключение параметр `-c` (кастомный конфигурационный файл).

`-c anotherapp.ini` - чтение конфигурационного файла, с иным названием. При использовании другие параметры запуска не используются и все параметры читаются из конфигурационного файла.

`-f index.html` - путь до html файла (относительный или полный).

`-a "https://youtube.com/tv"` - адрес веб-сайта.

`-n "My app"` - заголовок приложения.

`-i MyIcon.ico` - путь до иконки.

`-u Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:131.0) Gecko/20100101 Firefox/131.0` - пользовательский агент (user agent).

`-s 1.js` - пользовательский скрипт (userscript).

`-w` - ширина приложения.

`-h` - высота приложения.

`-fullscreen` - полноэкранный режим.

`-p` - изменение системной прокси на заданную (формат: IP:PORT).

`-rp` - возврат прошлой системной прокси, для случаев изменения прокси на другую.

`-b 3` - стиль рамок (None = `0`, Sizeable = `1`, Single = `2`, Dialog = 3, SizeToolWin = `4`, ToolWindow = `5`).

`-t 50` - отступ сверху.

`-l 50` - отступ справа.

`-d` - включение режима отладки.

## Команды хоста
`open app.exe` или `open "app.exe" -param1 -param2 "test"` - открытие приложения, можно использовать как полный путь, так и относительный.

`folder Apps\` - список файлов и папок.

`del 1.txt` - удаление файла.

`close` - закрытие приложения.

Подробнее об использовании можно посмотреть в файле `index.html`.

## Режим отладки
Для быстрой отладки можно включить специальный режим, в котором доступно: изменение размеров, изменение User agent, очистка всех данных. Для включения измените параметр `Debug` на `1`.

[![](https://github.com/user-attachments/assets/cae19d08-4951-44bf-8278-2edcf076eb75)](https://github.com/user-attachments/assets/5d2eafc3-2825-48c3-bc82-718ca471549d)

## Загрузка
>Версия для Windows 10, 11.<br>

**[Загрузить](https://github.com/r57zone/ProtonShell/releases)**

## Обратная связь
`r57zone[собака]gmail.com`