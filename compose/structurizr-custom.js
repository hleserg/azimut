// compose/structurizr-custom.js — кастомный JS для Structurizr Local (HLE-557).
// Инжектируется nginx-sidecar как <script src="..."> перед </head>, ПОСЛЕ
// загрузки hljs (он тоже в head), но ДО рендеринга Documentation в body.
//
// Зачем: убрать hljs WARN про неизвестный язык 'mermaid'. Мы НЕ хотим
// syntax-highlight для Mermaid (его рендеринг в Structurizr Documentation
// отдельная тема — HLE-539 баннер "открой на GitHub"), но и WARN убрать.
// Решение: зарегистрировать `mermaid` как пустую грамматику.

(function () {
    function tryRegister() {
        if (!window.hljs) return false;
        if (!window.hljs.getLanguage("mermaid")) {
            window.hljs.registerLanguage("mermaid", function () {
                return { contains: [] };
            });
        }
        return true;
    }
    // Шанс 1: hljs уже доступен (мы инжектимся после его <script> в <head>).
    if (tryRegister()) return;
    // Шанс 2 (defensive): hljs ещё не загружен — поллим до появления.
    var poll = setInterval(function () {
        if (tryRegister()) clearInterval(poll);
    }, 20);
})();
