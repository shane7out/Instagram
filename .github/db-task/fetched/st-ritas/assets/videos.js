/* St Rita's - videos start on hover.
   Hovering a card swaps its poster for a muted, autoplaying YouTube embed after a
   short delay (so sweeping the mouse across the wall doesn't start six of them).
   Leaving puts the poster back. Clicking keeps it playing and turns the sound on.
   On a touch screen there is no hover, so the first tap plays with sound.
   Nothing is loaded from YouTube until you actually ask for it. */
(function () {
  'use strict';

  var HOVER_DELAY = 170;   // ms of intent before we fetch anything
  var current = null;      // the frame that is playing right now
  var timer = null;

  function isTouch() {
    return window.matchMedia && window.matchMedia('(hover: none)').matches;
  }

  function embed(frame, muted) {
    var id = frame.getAttribute('data-vid');
    if (!id) return;
    var f = frame.querySelector('iframe');
    if (!f) {
      f = document.createElement('iframe');
      f.title = (frame.querySelector('.vid-play') || {}).ariaLabel || 'Video';
      f.allow = 'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture';
      f.setAttribute('allowfullscreen', '');
      f.setAttribute('loading', 'lazy');
      frame.appendChild(f);
    }
    f.src = 'https://www.youtube-nocookie.com/embed/' + id +
            '?autoplay=1&mute=' + (muted ? 1 : 0) +
            '&controls=' + (muted ? 0 : 1) +
            '&rel=0&modestbranding=1&playsinline=1&loop=1&playlist=' + id;
    frame.classList.add('playing');
    frame.classList.toggle('muted', !!muted);
    var sound = frame.querySelector('.vid-sound');
    if (sound) sound.textContent = muted ? 'Sound on' : 'Playing';
  }

  function stop(frame) {
    if (!frame) return;
    if (frame.classList.contains('locked')) return;   // clicked - leave it alone
    var f = frame.querySelector('iframe');
    if (f) f.parentNode.removeChild(f);
    frame.classList.remove('playing', 'muted');
  }

  function start(frame, muted) {
    if (!frame || frame === current) return;
    if (current && current !== frame) stop(current);
    current = frame;
    embed(frame, muted);
  }

  function bind(frame) {
    if (frame.dataset.bound) return;
    frame.dataset.bound = '1';

    if (!isTouch()) {
      frame.addEventListener('mouseenter', function () {
        clearTimeout(timer);
        timer = setTimeout(function () { start(frame, true); }, HOVER_DELAY);
      });
      frame.addEventListener('mouseleave', function () {
        clearTimeout(timer);
        if (frame === current) { stop(frame); current = null; }
      });
      // keyboard users get the same thing on focus
      frame.addEventListener('focusin', function () { start(frame, true); });
    }

    // click / tap: play for real, with sound, and keep it
    frame.addEventListener('click', function (ev) {
      var sound = ev.target.closest && ev.target.closest('.vid-sound');
      clearTimeout(timer);
      ev.preventDefault();
      if (sound && frame.classList.contains('playing') && !frame.classList.contains('muted')) {
        frame.classList.remove('locked');
        stop(frame);
        current = null;
        return;
      }
      frame.classList.add('locked');
      if (current && current !== frame) {
        current.classList.remove('locked');
        stop(current);
      }
      current = frame;
      embed(frame, false);
    });
  }

  function init() {
    var frames = document.querySelectorAll('.vid-frame[data-vid]');
    for (var i = 0; i < frames.length; i++) bind(frames[i]);
    if (isTouch()) {
      var cues = document.querySelectorAll('.vid-cue');
      for (var j = 0; j < cues.length; j++) cues[j].textContent = 'Tap to play';
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
