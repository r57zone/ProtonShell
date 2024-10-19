// Функция для поиска кнопки и добавления слушателя событий
function trackButton() {
    // Получаем все кнопки с указанным классом
    const buttons = document.querySelectorAll('.ytlr-button--large-shape');

    if (buttons.length > 1) { // Проверяем, есть ли хотя бы две кнопки
        const button = buttons[1]; // Выбираем вторую кнопку (индекс 1)

        //console.log('Вторая кнопка найдена, создаем дубликат.');

        // Создаем дубликат кнопки
        const newButton = button.cloneNode(true); // Клонируем кнопку, включая ее содержимое и атрибуты

        // Удаляем оригинальную кнопку
        const parent = button.parentNode; // Получаем родительский элемент
        if (parent) {
            parent.removeChild(button); // Удаляем оригинальную кнопку

            // Убираем aria-hidden у новой кнопки, чтобы она была доступна
            newButton.removeAttribute('aria-hidden'); // Удаляем атрибут aria-hidden
            newButton.setAttribute('tabindex', '0'); // Добавляем tabindex, чтобы кнопка могла получать фокус

            // Добавляем новый элемент на место оригинала
            newButton.addEventListener('click', function(event) {
				window.chrome.webview.postMessage('close');
                //alert('Кнопка нажата!'); // Показываем алерт
                //console.log('Кнопка нажата:', event);
                //console.dir(event.target);
            });

            // Вставляем дубликат в то же место
            parent.insertBefore(newButton, button.nextSibling); // Вставляем новый элемент после оригинала
            //console.log('Дубликат второй кнопки добавлен с обработчиком клика.');

            // Устанавливаем флаг, чтобы избежать повторной обработки
            // buttonProcessed = true; // Убираем этот флаг, чтобы кнопка могла заменяться повторно

            // Проверяем доступность новой кнопки
            //console.log('Новая кнопка:', newButton);
        } else {
            //console.error('Родительский элемент не найден.'); // Если родителя нет, выводим сообщение об ошибке
        }
    } else {
        //console.log('Недостаточно кнопок. Попробуем снова через 1 секунду.');
    }
}

// Дожидаемся полной загрузки документа
//console.log('Документ загружен, ищем кнопки...');

// Пробуем сразу найти кнопки
trackButton();

// Если кнопки не найдены сразу, ищем их периодически
const interval = setInterval(() => {
    trackButton(); // Теперь просто вызываем функцию
}, 1000);  // Проверяем каждые 1000 миллисекунд (1 секунда)
