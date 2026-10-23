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

function extOf(file) {
  const match = String(file || '').match(/\.([a-z0-9]+)$/i);
  return match ? match[1].toUpperCase() : 'BOOK';
}

hexo.extend.tag.register('ebook_list', function () {
  const data = hexo.locals.get('data') || {};
  const books = Array.isArray(data.books) ? data.books : [];

  if (!books.length) {
    return [
      '<div class="book-empty">',
      '<i class="fas fa-book-open"></i>',
      '<p>书架还是空的。</p>',
      '<p class="book-empty-hint">双击电脑桌面上的「上传电子书」，选几个 EPUB / PDF 文件，这里就会出现下载卡片。</p>',
      '</div>'
    ].join('');
  }

  const cards = books.map(function (book) {
    const file = book.file || '';
    const title = book.title || '未命名电子书';
    const author = book.author || '';
    const format = (book.format || extOf(file)).toUpperCase();
    const size = book.size || '';
    const date = formatDate(book.date);
    const desc = book.desc || '';
    const cover = book.cover ? String(book.cover) : '';

    const coverHtml = cover
      ? '<div class="book-cover has-image"><img src="' + escapeHtml(cover) + '" alt="' + escapeHtml(title) + '"></div>'
      : [
          '<div class="book-cover" data-format="' + escapeHtml(format) + '">',
          '<i class="fas fa-book-open"></i>',
          '<span class="book-format">' + escapeHtml(format) + '</span>',
          '</div>'
        ].join('');

    const meta = [author, format, size].filter(Boolean).join(' · ');

    return [
      '<article class="book-card">',
      coverHtml,
      '<div class="book-body">',
      '<h2 class="book-title">' + escapeHtml(title) + '</h2>',
      meta ? '<p class="book-meta">' + escapeHtml(meta) + '</p>' : '',
      desc ? '<p class="book-desc">' + escapeHtml(desc) + '</p>' : '',
      '<div class="book-foot">',
      '<a class="book-download" href="' + escapeHtml(file) + '" download>下载 <i class="fas fa-download"></i></a>',
      date ? '<span class="book-date">' + escapeHtml(date) + '</span>' : '',
      '</div>',
      '</div>',
      '</article>'
    ].join('');
  });

  return '<div class="book-grid">' + cards.join('') + '</div>';
});
