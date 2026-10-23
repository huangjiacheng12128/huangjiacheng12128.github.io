'use strict';

function escapeHtml(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function formatDate(value) {
  if (!value) return '';
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value);
}

hexo.extend.tag.register('photo_gallery', function () {
  const data = hexo.locals.get('data') || {};
  const photos = Array.isArray(data.photos) ? data.photos : [];

  if (!photos.length) {
    return [
      '<div class="photo-empty">',
      '<i class="fas fa-camera-retro"></i>',
      '<p>相册还是空的。</p>',
      '<p class="photo-empty-hint">双击电脑桌面上的「上传照片」，选几张图片，这里就会自动排成一面照片墙。</p>',
      '</div>'
    ].join('');
  }

  const figures = photos.map(function (photo) {
    const src = photo.src || '';
    const caption = photo.caption || '';
    const date = formatDate(photo.date);
    return [
      '<figure class="photo-item">',
      '<a href="' + escapeHtml(src) + '" data-fancybox="photo-gallery" data-caption="' + escapeHtml(caption) + '">',
      '<img src="' + escapeHtml(src) + '" alt="' + escapeHtml(caption) + '" loading="lazy">',
      '</a>',
      '<figcaption>',
      '<span class="photo-caption">' + escapeHtml(caption) + '</span>',
      date ? '<span class="photo-date">' + escapeHtml(date) + '</span>' : '',
      '</figcaption>',
      '</figure>'
    ].join('');
  });

  return '<div class="photo-grid">' + figures.join('') + '</div>';
});
