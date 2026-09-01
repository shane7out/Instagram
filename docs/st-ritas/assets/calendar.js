// St Rita's Retreat — availability calendar.
//
// Renders a month grid from data/availability.json. Dates listed in that file
// are nights occupied, inclusive of both endpoints. Selecting an arrival and a
// departure fills the inquiry form below the calendar.

(function () {
  var mount = document.getElementById('calendar');
  if (!mount) return;

  var MONTHS_AHEAD = 18;
  var MONTH_NAMES = ['January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];
  var DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  var STATUS_LABELS = { booked: 'Booked', held: 'On hold', closed: 'Closed' };

  var today = startOfDay(new Date());
  var firstMonth = new Date(today.getFullYear(), today.getMonth(), 1);
  var lastMonth = new Date(today.getFullYear(), today.getMonth() + MONTHS_AHEAD, 1);
  var view = new Date(firstMonth);

  var blocks = [];
  var dataState = 'loading'; // loading | ready | unavailable
  var selection = { arrive: null, depart: null };

  loadData();
  render();

  function loadData() {
    // Opened straight from the filesystem, fetch() is blocked by the browser.
    // The calendar still renders — it just cannot mark anything as taken.
    fetch('data/availability.json', { cache: 'no-store' })
      .then(function (response) {
        if (!response.ok) throw new Error('HTTP ' + response.status);
        return response.json();
      })
      .then(function (data) {
        blocks = (data.blocks || []).map(function (block) {
          return {
            start: parseDate(block.start),
            end: parseDate(block.end || block.start),
            status: block.status || 'booked',
            label: block.label || ''
          };
        }).filter(function (block) { return block.start && block.end; });
        dataState = 'ready';
        render();
      })
      .catch(function () {
        dataState = 'unavailable';
        render();
      });
  }

  // ---------- date helpers ----------

  function startOfDay(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  function parseDate(value) {
    var match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(value || '').trim());
    if (!match) return null;
    // Built from parts so the date stays local rather than shifting via UTC.
    return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  }

  function toISO(date) {
    return date.getFullYear() + '-' +
      pad(date.getMonth() + 1) + '-' +
      pad(date.getDate());
  }

  function pad(value) { return (value < 10 ? '0' : '') + value; }

  function addDays(date, count) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + count);
  }

  function sameDay(a, b) {
    return a && b && a.getTime() === b.getTime();
  }

  function nightsBetween(arrive, depart) {
    return Math.round((depart - arrive) / 86400000);
  }

  function longDate(date) {
    return MONTH_NAMES[date.getMonth()].slice(0, 3) + ' ' + date.getDate() + ', ' + date.getFullYear();
  }

  // ---------- availability ----------

  function statusFor(date) {
    for (var i = 0; i < blocks.length; i++) {
      if (date >= blocks[i].start && date <= blocks[i].end) return blocks[i];
    }
    return null;
  }

  function isSelectable(date) {
    return date >= today && !statusFor(date);
  }

  // Every night from arrival up to (not including) departure must be free.
  function rangeIsFree(arrive, depart) {
    for (var d = new Date(arrive); d < depart; d = addDays(d, 1)) {
      if (statusFor(d)) return false;
    }
    return true;
  }

  function inSelection(date) {
    if (!selection.arrive || !selection.depart) return false;
    return date > selection.arrive && date < selection.depart;
  }

  // ---------- rendering ----------

  function render() {
    mount.innerHTML = '';
    mount.appendChild(buildControls());
    mount.appendChild(buildGrid());
    mount.appendChild(buildLegend());
    mount.appendChild(buildSummary());
  }

  function buildControls() {
    var bar = el('div', 'cal-controls');

    var prev = el('button', 'cal-nav');
    prev.type = 'button';
    prev.innerHTML = '&larr;';
    prev.setAttribute('aria-label', 'Previous month');
    prev.disabled = view <= firstMonth;
    prev.addEventListener('click', function () { shiftMonth(-1); });

    var heading = el('h3', 'cal-month');
    heading.id = 'cal-month-label';
    heading.setAttribute('aria-live', 'polite');
    heading.textContent = MONTH_NAMES[view.getMonth()] + ' ' + view.getFullYear();

    var next = el('button', 'cal-nav');
    next.type = 'button';
    next.innerHTML = '&rarr;';
    next.setAttribute('aria-label', 'Next month');
    next.disabled = view >= lastMonth;
    next.addEventListener('click', function () { shiftMonth(1); });

    bar.appendChild(prev);
    bar.appendChild(heading);
    bar.appendChild(next);
    return bar;
  }

  function shiftMonth(delta) {
    var candidate = new Date(view.getFullYear(), view.getMonth() + delta, 1);
    if (candidate < firstMonth || candidate > lastMonth) return;
    view = candidate;
    render();
  }

  function buildGrid() {
    var grid = el('div', 'cal-grid');
    grid.setAttribute('role', 'grid');
    grid.setAttribute('aria-labelledby', 'cal-month-label');

    DAY_NAMES.forEach(function (name) {
      var head = el('div', 'cal-dow');
      head.setAttribute('role', 'columnheader');
      head.setAttribute('aria-label', name);
      head.textContent = name.charAt(0);
      grid.appendChild(head);
    });

    var monthStart = new Date(view.getFullYear(), view.getMonth(), 1);
    var daysInMonth = new Date(view.getFullYear(), view.getMonth() + 1, 0).getDate();

    for (var blank = 0; blank < monthStart.getDay(); blank++) {
      grid.appendChild(el('div', 'cal-blank'));
    }

    for (var day = 1; day <= daysInMonth; day++) {
      grid.appendChild(buildDay(new Date(view.getFullYear(), view.getMonth(), day)));
    }

    return grid;
  }

  function buildDay(date) {
    var block = statusFor(date);
    var past = date < today;
    // A departure is not a night stayed, so a day that is taken can still be
    // offered as a checkout date once the nights before it are clear.
    var asDeparture = !past && block && selection.arrive && !selection.depart &&
      date > selection.arrive && rangeIsFree(selection.arrive, date);
    var selectable = isSelectable(date) || asDeparture;

    var cell = el('button', 'cal-day');
    cell.type = 'button';
    cell.textContent = String(date.getDate());
    cell.setAttribute('role', 'gridcell');

    var description = longDate(date);

    if (past) {
      cell.classList.add('is-past');
      cell.disabled = true;
      description += ', in the past';
    } else if (block) {
      cell.classList.add('is-' + block.status);
      cell.disabled = !asDeparture;
      description += ', ' + (STATUS_LABELS[block.status] || 'unavailable').toLowerCase();
      if (block.label) description += ' — ' + block.label;
      if (asDeparture) {
        cell.classList.add('is-checkout');
        description += ', available as a departure date';
      }
    } else {
      description += ', available';
    }

    if (sameDay(date, selection.arrive)) {
      cell.classList.add('is-arrive');
      description += ', selected arrival';
    }
    if (sameDay(date, selection.depart)) {
      cell.classList.add('is-depart');
      description += ', selected departure';
    }
    if (inSelection(date)) cell.classList.add('is-between');
    if (sameDay(date, today)) cell.classList.add('is-today');

    cell.setAttribute('aria-label', description);
    if (selectable) {
      cell.addEventListener('click', function () { pick(date); });
    }

    return cell;
  }

  // Departure day is not a night stayed, so it may itself be booked — only the
  // nights in between have to be clear.
  function pick(date) {
    if (!selection.arrive || selection.depart || date <= selection.arrive) {
      selection.arrive = date;
      selection.depart = null;
    } else if (rangeIsFree(selection.arrive, date)) {
      selection.depart = date;
    } else {
      selection.arrive = date;
      selection.depart = null;
    }
    syncForm();
    render();
  }

  function buildLegend() {
    var legend = el('div', 'cal-legend');
    [
      ['is-free', 'Available'],
      ['is-held', 'On hold'],
      ['is-booked', 'Booked'],
      ['is-closed', 'Closed']
    ].forEach(function (entry) {
      var item = el('span', 'cal-key');
      item.appendChild(el('i', 'cal-swatch ' + entry[0]));
      item.appendChild(document.createTextNode(entry[1]));
      legend.appendChild(item);
    });
    return legend;
  }

  function buildSummary() {
    var summary = el('p', 'cal-summary');
    summary.setAttribute('role', 'status');

    if (dataState === 'loading') {
      summary.textContent = 'Loading availability…';
      return summary;
    }

    if (dataState === 'unavailable') {
      summary.classList.add('is-warning');
      summary.textContent = 'Live availability could not be loaded, so no dates are marked as taken. ' +
        'Please confirm your dates with us before counting on them.';
      return summary;
    }

    if (selection.arrive && selection.depart) {
      var nights = nightsBetween(selection.arrive, selection.depart);
      summary.textContent = 'Arriving ' + longDate(selection.arrive) +
        ', departing ' + longDate(selection.depart) +
        ' — ' + nights + (nights === 1 ? ' night' : ' nights') +
        '. Your dates are filled in below.';
      var clear = el('button', 'cal-clear');
      clear.type = 'button';
      clear.textContent = 'Clear';
      clear.addEventListener('click', function () {
        selection.arrive = selection.depart = null;
        syncForm();
        render();
      });
      summary.appendChild(document.createTextNode(' '));
      summary.appendChild(clear);
    } else if (selection.arrive) {
      summary.textContent = 'Arriving ' + longDate(selection.arrive) + '. Now choose your departure date.';
    } else {
      summary.textContent = 'Select an arrival date, then a departure date.';
    }

    return summary;
  }

  function syncForm() {
    setField('arrive', selection.arrive);
    setField('depart', selection.depart);
  }

  function setField(id, date) {
    var field = document.getElementById(id);
    if (field) field.value = date ? toISO(date) : '';
  }

  function el(tag, className) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    return node;
  }
})();
