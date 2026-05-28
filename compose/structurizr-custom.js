// compose/structurizr-custom.js — кастомный JS для Structurizr Local (HLE-557).
// Инжектируется nginx-sidecar как <script src="..."> перед </body>.
//
// Зачем: убрать hljs WARN про неизвестный язык 'mermaid'. Мы НЕ хотим
// syntax-highlight для Mermaid (это всё равно не превращается в нормальную
// диаграмму в Structurizr Documentation) — но и WARN'и в консоли убрать.
// Решение: зарегистрировать `mermaid` как пустую грамматику.

(function () {
    var poll = setInterval(function () {
        if (!window.hljs) return;
        clearInterval(poll);
        if (!window.hljs.getLanguage("mermaid")) {
            window.hljs.registerLanguage("mermaid", function () {
                return { contains: [] };
            });
        }
    }, 50);
})();
