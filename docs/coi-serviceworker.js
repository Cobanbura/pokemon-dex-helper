/*! coi-serviceworker v0.1.7 - MIT License - https://github.com/gzuidhof/coi-serviceworker */
if (typeof window === 'undefined') {
    self.addEventListener("install", () => self.skipWaiting());
    self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));

    self.addEventListener("fetch", (event) => {
        if (event.request.cache === "only-if-cached" && event.request.mode !== "same-origin") {
            return;
        }

        event.respondWith(
            fetch(event.request).then((response) => {
                if (response.status === 0) {
                    return response;
                }

                const newHeaders = new Headers(response.headers);
                newHeaders.set("Cross-Origin-Embedder-Policy", "require-corp");
                newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");

                return new Headers(response.headers).get("Content-Type")?.includes("text/html") 
                    ? response.text().then(html => new Response(html.replace(/<script/, `<script src="${self.location.pathname}"`), {
                        fields: response.fields,
                        status: response.status,
                        statusText: response.statusText,
                        headers: newHeaders
                    }))
                    : new Response(response.body, {
                        status: response.status,
                        statusText: response.statusText,
                        headers: newHeaders,
                    });
            })
        );
    });
} else {
    const n = window.navigator;
    if (n.serviceWorker && n.serviceWorker.register) {
        n.serviceWorker.register(window.document.currentScript.src);
    }
}