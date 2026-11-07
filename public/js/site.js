// ── Mobile nav ─────────────────────────────────────────────
const burger = document.getElementById('burger');
const navLinks = document.getElementById('navLinks');
if (burger && navLinks) {
  burger.addEventListener('click', () => navLinks.classList.toggle('open'));
  navLinks.querySelectorAll('a').forEach((a) =>
    a.addEventListener('click', () => navLinks.classList.remove('open')),
  );
}

// ── Nav elevation on scroll ────────────────────────────────
const nav = document.getElementById('nav');
if (nav) {
  const onScroll = () => {
    nav.style.background =
      window.scrollY > 10 ? 'rgba(4, 13, 24, 0.92)' : 'rgba(4, 13, 24, 0.72)';
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
}

// ── Reveal on scroll (staggered) ───────────────────────────
const revealEls = document.querySelectorAll('.reveal');
if ('IntersectionObserver' in window && revealEls.length) {
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in');
          io.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.12 },
  );
  revealEls.forEach((el) => io.observe(el));
} else {
  revealEls.forEach((el) => el.classList.add('in'));
}
