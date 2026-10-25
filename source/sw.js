/* 博客缓存修复：页面永远优先取网络，避免 GitHub Pages 的 10 分钟 HTML 缓存
   配合 /js/sw-register.js 注册使用。 */
const HTML_CACHE = 'blog-html-v1';
const ASSET_CACHE = 'blog-asset-v1';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== HTML_CACHE && key !== ASSET_CACHE)
          .map((key) => caches.delete(key))
      )
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.startsWith('/books/files/')) return;
  if (request.headers.has('range')) return;

  const accept = request.headers.get('accept') || '';
  const isHTML = request.mode === 'navigate' || accept.includes('text/html');

  if (isHTML) {
    event.respondWith(networkFirstHTML(request));
    return;
  }

  const needsFresh = /\.(css|js|json|xml)$/i.test(url.pathname);
  event.respondWith(
    needsFresh ? networkFirst(request, ASSET_CACHE) : staleWhileRevalidate(request, ASSET_CACHE)
  );
});

async function networkFirstHTML(request) {
  const cache = await caches.open(HTML_CACHE);
  try {
    const fresh = new URL(request.url);
    fresh.searchParams.set('_sw', Date.now().toString());
    const response = await fetch(fresh.toString(), {
      cache: 'no-store',
      credentials: 'same-origin'
    });
    if (response && response.ok) {
      await cache.put(request, response.clone()).catch(() => {});
    }
    return response;
  } catch (error) {
    const cached = await cache.match(request);
    if (cached) return cached;
    const home = await cache.match('/');
    if (home) return home;
    return Response.error();
  }
}

async function networkFirst(request, cacheName) {
  const cache = await caches.open(cacheName);
  try {
    const response = await fetch(request, { cache: 'no-store' });
    if (response && response.ok) {
      await cache.put(request, response.clone()).catch(() => {});
    }
    return response;
  } catch (error) {
    const cached = await cache.match(request);
    if (cached) return cached;
    throw error;
  }
}

async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  const network = fetch(request)
    .then(async (response) => {
      if (response && response.ok) {
        await cache.put(request, response.clone()).catch(() => {});
      }
      return response;
    })
    .catch(() => null);

  if (cached) return cached;
  const response = await network;
  return response || Response.error();
}
