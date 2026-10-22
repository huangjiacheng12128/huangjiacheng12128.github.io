/* 不蒜子兜底：统计服务无响应时（常见 502），不再无限转圈 */
(function () {
  var targets = [
    { id: 'busuanzi_value_page_pv', box: '.post-meta-pv-cv' },
    { id: 'busuanzi_value_site_uv', box: '.webinfo-item' },
    { id: 'busuanzi_value_site_pv', box: '.webinfo-item' }
  ];

  function fallback() {
    targets.forEach(function (t) {
      var el = document.getElementById(t.id);
      if (!el || !el.querySelector('.fa-spinner')) return;
      var box = el.closest(t.box) || el;
      box.style.display = 'none';
    });
  }

  var timer = function () {
    setTimeout(fallback, 6000);
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', timer);
  } else {
    timer();
  }
  window.addEventListener('load', timer);
  ['pjax:complete', 'pjax:end'].forEach(function (evt) {
    document.addEventListener(evt, timer);
  });
})();
