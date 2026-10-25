/* 注册 /sw.js：之后的页面导航都走网络优先，不再被 GitHub Pages 的 HTML 缓存拖住 */
(function () {
  if (!('serviceWorker' in navigator)) return;

  var reloading = false;
  var firstInstall = !navigator.serviceWorker.controller;

  navigator.serviceWorker.addEventListener('controllerchange', function () {
    if (firstInstall) {
      firstInstall = false;
      return;
    }
    if (reloading) return;
    reloading = true;
    window.location.reload();
  });

  window.addEventListener('load', function () {
    navigator.serviceWorker
      .register('/sw.js', { scope: '/', updateViaCache: 'none' })
      .then(function (registration) {
        registration.update();
      })
      .catch(function () {
        /* 浏览器不支持或非 HTTPS 时静默失败，不影响正常浏览 */
      });
  });
})();
