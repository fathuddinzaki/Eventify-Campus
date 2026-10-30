/* ===================================
   EVENTIFY CAMPUS — PRESENTATION JS
   Slide Navigation & Animations
   =================================== */

(function () {
    'use strict';

    // --- State ---
    let currentSlide = 1;
    const totalSlides = document.querySelectorAll('.slide').length;
    let isTransitioning = false;
    let touchStartX = 0;
    let touchEndX = 0;

    // --- DOM References ---
    const slides = document.querySelectorAll('.slide');
    const progressFill = document.getElementById('progressFill');
    const slideCounter = document.getElementById('slideCounter');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    const shortcutHint = document.getElementById('shortcutHint');

    // --- Initialize ---
    function init() {
        // Deactivate all slides first, then show slide 1
        slides.forEach(s => {
            s.classList.remove('active', 'exit-left');
            s.style.transform = '';
            s.style.opacity = '';
        });

        const firstSlide = document.querySelector('.slide[data-slide="1"]');
        if (firstSlide) {
            firstSlide.classList.add('active');
            // Trigger entrance animations after a small delay so CSS transitions fire
            setTimeout(() => triggerAnimations(firstSlide), 100);
        }

        updateProgress();
        updateCounter();
        setupKeyboardNav();
        setupTouchNav();
        setupClickNav();
        hideHintAfterDelay();
    }

    // --- Slide Navigation (exposed globally for onclick handlers) ---
    window.changeSlide = function (direction) {
        if (isTransitioning) return;

        const nextSlideNum = currentSlide + direction;
        if (nextSlideNum < 1 || nextSlideNum > totalSlides) return;

        navigateToSlide(nextSlideNum, direction > 0 ? 'forward' : 'backward');
    };

    function navigateToSlide(slideNum, direction) {
        if (isTransitioning || slideNum === currentSlide) return;
        isTransitioning = true;

        const currentEl = document.querySelector(`.slide[data-slide="${currentSlide}"]`);
        const nextEl = document.querySelector(`.slide[data-slide="${slideNum}"]`);

        if (!currentEl || !nextEl) {
            isTransitioning = false;
            return;
        }

        // 1. Prepare: reset animations on the incoming slide
        resetAnimations(nextEl);

        // 2. Position the incoming slide off-screen (disable transition temporarily)
        nextEl.style.transition = 'none';
        if (direction === 'forward') {
            nextEl.style.transform = 'translateX(60px)';
        } else {
            nextEl.style.transform = 'translateX(-60px)';
        }
        nextEl.style.opacity = '0';
        nextEl.style.visibility = 'visible';

        // Force a reflow so the browser registers the starting position
        void nextEl.offsetWidth;

        // 3. Re-enable transitions and animate both slides
        nextEl.style.transition = '';

        // Animate current slide out
        currentEl.classList.remove('active');
        if (direction === 'forward') {
            currentEl.classList.add('exit-left');
        } else {
            currentEl.style.transform = 'translateX(60px)';
            currentEl.style.opacity = '0';
        }

        // Animate next slide in
        nextEl.style.transform = 'translateX(0)';
        nextEl.style.opacity = '1';
        nextEl.classList.add('active');

        // Trigger staggered element animations
        triggerAnimations(nextEl);

        // Update state
        currentSlide = slideNum;
        updateProgress();
        updateCounter();

        // 4. Clean up after transition completes
        setTimeout(() => {
            currentEl.classList.remove('exit-left');
            currentEl.style.transform = '';
            currentEl.style.opacity = '';
            currentEl.style.visibility = '';
            // Clear inline styles on the now-active slide so CSS rules take over
            nextEl.style.transform = '';
            nextEl.style.opacity = '';
            nextEl.style.visibility = '';
            isTransitioning = false;
        }, 700);
    }

    // --- Update UI ---
    function updateProgress() {
        const progress = (currentSlide / totalSlides) * 100;
        if (progressFill) progressFill.style.width = `${progress}%`;
    }

    function updateCounter() {
        const curr = String(currentSlide).padStart(2, '0');
        const total = String(totalSlides).padStart(2, '0');
        if (slideCounter) slideCounter.textContent = `${curr} / ${total}`;

        // Update button states
        if (prevBtn) {
            prevBtn.style.opacity = currentSlide === 1 ? '0.3' : '1';
            prevBtn.style.pointerEvents = currentSlide === 1 ? 'none' : 'auto';
        }
        if (nextBtn) {
            nextBtn.style.opacity = currentSlide === totalSlides ? '0.3' : '1';
            nextBtn.style.pointerEvents = currentSlide === totalSlides ? 'none' : 'auto';
        }
    }

    // --- Animations ---
    function resetAnimations(slideEl) {
        slideEl.querySelectorAll('.animate-in').forEach(el => {
            el.style.transition = 'none';
            el.style.opacity = '0';
            el.style.transform = 'translateY(24px)';
            // Force reflow
            void el.offsetWidth;
            el.style.transition = '';
        });
    }

    function triggerAnimations(slideEl) {
        slideEl.querySelectorAll('.animate-in').forEach(el => {
            const delay = parseInt(el.dataset.delay) || 0;
            setTimeout(() => {
                el.style.opacity = '1';
                el.style.transform = 'translateY(0)';
            }, delay + 80);
        });
    }

    // --- Keyboard Navigation ---
    function setupKeyboardNav() {
        document.addEventListener('keydown', (e) => {
            switch (e.key) {
                case 'ArrowRight':
                case 'ArrowDown':
                case ' ':
                case 'PageDown':
                    e.preventDefault();
                    changeSlide(1);
                    break;
                case 'ArrowLeft':
                case 'ArrowUp':
                case 'PageUp':
                    e.preventDefault();
                    changeSlide(-1);
                    break;
                case 'Home':
                    e.preventDefault();
                    navigateToSlide(1, 'backward');
                    break;
                case 'End':
                    e.preventDefault();
                    navigateToSlide(totalSlides, 'forward');
                    break;
            }

            // Number keys for direct slide jump (1-9, 0=10)
            const num = parseInt(e.key);
            if (!isNaN(num) && num >= 1 && num <= totalSlides) {
                const dir = num > currentSlide ? 'forward' : 'backward';
                navigateToSlide(num, dir);
            }
        });
    }

    // --- Touch / Swipe Navigation ---
    function setupTouchNav() {
        const container = document.getElementById('slidesContainer');
        if (!container) return;

        container.addEventListener('touchstart', (e) => {
            touchStartX = e.changedTouches[0].screenX;
        }, { passive: true });

        container.addEventListener('touchend', (e) => {
            touchEndX = e.changedTouches[0].screenX;
            handleSwipe();
        }, { passive: true });
    }

    function handleSwipe() {
        const threshold = 50;
        const diff = touchStartX - touchEndX;

        if (Math.abs(diff) > threshold) {
            if (diff > 0) {
                changeSlide(1); // Swipe left → next
            } else {
                changeSlide(-1); // Swipe right → previous
            }
        }
    }

    // --- Click Navigation (click on sides) ---
    function setupClickNav() {
        const container = document.getElementById('slidesContainer');
        if (!container) return;

        container.addEventListener('click', (e) => {
            // Don't trigger on buttons, links, or interactive elements
            if (e.target.closest('button, a, .nav-controls, .slide-nav, .shortcut-hint')) return;

            const x = e.clientX;
            const width = window.innerWidth;

            if (x > width * 0.75) {
                changeSlide(1);
            } else if (x < width * 0.25) {
                changeSlide(-1);
            }
        });
    }

    // --- Hide hint after first interaction ---
    function hideHintAfterDelay() {
        // Auto-hide after 5s
        setTimeout(() => {
            if (shortcutHint) shortcutHint.classList.add('hidden');
        }, 5000);

        // Or hide on first keypress / click
        const hideOnce = () => {
            if (shortcutHint) shortcutHint.classList.add('hidden');
            document.removeEventListener('keydown', hideOnce);
        };
        document.addEventListener('keydown', hideOnce);
    }

    // --- Mouse wheel navigation ---
    let wheelTimeout;
    document.addEventListener('wheel', (e) => {
        if (wheelTimeout) return;

        wheelTimeout = setTimeout(() => {
            wheelTimeout = null;
        }, 800);

        if (e.deltaY > 30) {
            changeSlide(1);
        } else if (e.deltaY < -30) {
            changeSlide(-1);
        }
    }, { passive: true });

    // --- Start ---
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
