(() => {
  const body = document.body;

  function activateNav() {
    const current = location.pathname.toLowerCase();
    document.querySelectorAll('.nav-link[href]').forEach((a) => {
      const href = (a.getAttribute('href') || '').toLowerCase();
      if (!href || href === '#') return;

      const isRoot = href === '/';
      const active = isRoot ? current === '/' : current.startsWith(href);
      a.classList.toggle('is-active', active);
    });
  }

  function setupRevealOnScroll() {
    const items = document.querySelectorAll('.reveal-on-scroll');
    if (!items.length || !('IntersectionObserver' in window)) {
      items.forEach((el) => el.classList.add('revealed'));
      return;
    }

    const io = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('revealed');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12 });

    items.forEach((el) => io.observe(el));
  }

  function setupTiltCards() {
    const cards = document.querySelectorAll('.tilt-card');
    cards.forEach((card) => {
      card.addEventListener('mousemove', (ev) => {
        const rect = card.getBoundingClientRect();
        const x = (ev.clientX - rect.left) / rect.width;
        const y = (ev.clientY - rect.top) / rect.height;
        const rotY = (x - 0.5) * 7;
        const rotX = (0.5 - y) * 7;
        card.style.transform = `perspective(950px) rotateX(${rotX}deg) rotateY(${rotY}deg) translateY(-4px)`;
      });

      card.addEventListener('mouseleave', () => {
        card.style.transform = '';
      });
    });
  }

  function setupHeaderState() {
    const header = document.getElementById('luxHeader');
    if (!header) return;

    const refresh = () => {
      header.classList.toggle('scrolled', window.scrollY > 8);
    };

    refresh();
    window.addEventListener('scroll', refresh, { passive: true });
  }

  function setupProfileMenu() {
    const menu = document.querySelector('[data-profile-menu]');
    const toggle = document.getElementById('profileMenuToggle');
    const panel = document.getElementById('profileMenuPanel');
    if (!menu || !toggle || !panel) return;

    const close = () => {
      menu.classList.remove('open');
      toggle.setAttribute('aria-expanded', 'false');
    };

    const open = () => {
      menu.classList.add('open');
      toggle.setAttribute('aria-expanded', 'true');
    };

    toggle.addEventListener('click', () => {
      if (menu.classList.contains('open')) close();
      else open();
    });

    document.addEventListener('click', (event) => {
      if (!menu.contains(event.target)) {
        close();
      }
    });

    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') close();
    });
  }

  function setupDockMenu() {
    const dock = document.querySelector('.quick-dock');
    const internalToggle = document.getElementById('dockToggle');
    const externalToggle = document.getElementById('mobileNavToggle');
    const mobileProfilePanel = document.getElementById('mobileProfileSheet');
    const mobileProfileToggle = document.getElementById('mobileProfileToggle');
    const toggles = [internalToggle, externalToggle].filter(Boolean);
    if (!dock || !toggles.length) return;

    const isMobile = () => window.matchMedia('(max-width: 900px)').matches;
    const syncExpandedState = () => {
      const expanded = !dock.classList.contains('collapsed');
      toggles.forEach((btn) => btn.setAttribute('aria-expanded', String(expanded)));
    };
    const closeDock = () => {
      dock.classList.add('collapsed');
      syncExpandedState();
    };

    dock.classList.add('collapsed');
    syncExpandedState();

    toggles.forEach((btn) => {
      btn.addEventListener('click', (event) => {
        event.stopPropagation();
        dock.classList.toggle('collapsed');
        if (!dock.classList.contains('collapsed') && mobileProfilePanel && mobileProfileToggle) {
          mobileProfilePanel.classList.remove('open');
          mobileProfileToggle.setAttribute('aria-expanded', 'false');
        }
        syncExpandedState();
      });
    });

    document.addEventListener('click', (event) => {
      if (!isMobile()) return;
      if (dock.contains(event.target)) return;
      if (externalToggle && externalToggle.contains(event.target)) return;
      closeDock();
    });

    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        closeDock();
      }
    });

    const revealDock = () => {
      if (!isMobile()) {
        dock.classList.remove('mobile-ready');
        closeDock();
        return;
      }

      window.setTimeout(() => {
        dock.classList.add('mobile-ready');
      }, 220);
    };

    revealDock();
    window.addEventListener('resize', revealDock, { passive: true });
  }

  function setupMobileProfileSheet() {
    const toggle = document.getElementById('mobileProfileToggle');
    const panel = document.getElementById('mobileProfileSheet');
    if (!toggle || !panel) return;

    const isMobile = () => window.matchMedia('(max-width: 900px)').matches;
    const close = () => {
      panel.classList.remove('open');
      toggle.setAttribute('aria-expanded', 'false');
    };
    const open = () => {
      const dock = document.querySelector('.quick-dock');
      if (dock) {
        dock.classList.add('collapsed');
        const navToggle = document.getElementById('mobileNavToggle');
        if (navToggle) navToggle.setAttribute('aria-expanded', 'false');
      }
      panel.classList.add('open');
      toggle.setAttribute('aria-expanded', 'true');
    };

    toggle.addEventListener('click', (event) => {
      event.stopPropagation();
      if (panel.classList.contains('open')) close();
      else open();
    });

    document.addEventListener('click', (event) => {
      if (!isMobile()) return;
      if (panel.contains(event.target) || toggle.contains(event.target)) return;
      close();
    });

    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') close();
    });

    panel.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', () => close());
    });

    window.addEventListener('resize', () => {
      if (!isMobile()) close();
    }, { passive: true });
  }

  function setupDetailedFilter() {
    const check = document.getElementById('detailedFilterToggle');
    const box = document.getElementById('detailedFilterBox');
    if (!check || !box) return;

    const refresh = () => {
      box.classList.toggle('open', check.checked);
    };
    refresh();
    check.addEventListener('change', refresh);
  }

  function setupImagePreview() {
    const fileInput = document.querySelector('[data-image-upload]');
    const urlInput = document.querySelector('[data-image-url]');
    const coverInput = document.querySelector('[data-cover-image-input]');
    const preview = document.getElementById('livePreviewImage');
    const uploadZone = document.querySelector('.upload-zone');

    if (!preview) return;
    if (!preview.getAttribute('src')) {
      preview.closest('.live-preview')?.classList.add('empty');
    }

    if (urlInput) {
      urlInput.addEventListener('input', () => {
        const value = urlInput.value.trim();
        if (value.length > 4) {
          preview.src = value;
          preview.closest('.live-preview')?.classList.remove('empty');
        }
      });
    }

    if (fileInput) {
      fileInput.addEventListener('change', () => {
        const file = fileInput.files?.[0];
        if (!file) return;

        const objectUrl = URL.createObjectURL(file);
        preview.src = objectUrl;
        preview.closest('.live-preview')?.classList.remove('empty');
        preview.onload = () => URL.revokeObjectURL(objectUrl);
      });
    }

    document.querySelectorAll('[data-cover-choice]').forEach((choice) => {
      choice.addEventListener('change', () => {
        if (!choice.checked) return;
        if (coverInput) coverInput.value = choice.value;
        preview.src = choice.value;
        document.querySelectorAll('.cover-choice').forEach((item) => item.classList.remove('selected'));
        choice.closest('.cover-choice')?.classList.add('selected');
      });
    });

    if (!uploadZone || !fileInput) return;

    ['dragenter', 'dragover'].forEach((type) => {
      uploadZone.addEventListener(type, (e) => {
        e.preventDefault();
        uploadZone.classList.add('dragging');
      });
    });

    ['dragleave', 'drop'].forEach((type) => {
      uploadZone.addEventListener(type, (e) => {
        e.preventDefault();
        uploadZone.classList.remove('dragging');
      });
    });

    uploadZone.addEventListener('drop', (e) => {
      const file = e.dataTransfer?.files?.[0];
      if (!file) return;

      const dt = new DataTransfer();
      dt.items.add(file);
      fileInput.files = dt.files;
      fileInput.dispatchEvent(new Event('change'));
    });
  }

  function setupListingSubmitGuard() {
    const form = document.getElementById('listingForm');
    if (!form) return;

    let submitted = false;
    form.addEventListener('submit', (e) => {
      if (typeof form.checkValidity === 'function' && !form.checkValidity()) {
        submitted = false;
        return;
      }

      if (submitted) {
        e.preventDefault();
        return;
      }
      submitted = true;

      const submitBtn = document.getElementById('listingSubmitBtn');
      if (submitBtn) {
        submitBtn.setAttribute('disabled', 'disabled');
        submitBtn.textContent = 'Kaydediliyor...';
      }
    });
  }

  function setupLocationSelectors() {
    const provinceSelect = document.querySelector('[data-province-select]');
    const districtSelect = document.querySelector('[data-district-select]');
    if (!provinceSelect || !districtSelect) return;

    let locationMap = {};
    try {
      locationMap = JSON.parse(provinceSelect.getAttribute('data-location-map') || '{}');
    } catch {
      locationMap = {};
    }

    const fillDistricts = () => {
      const province = provinceSelect.value;
      const districts = locationMap[province] || [];
      const current = districtSelect.value || districtSelect.getAttribute('data-selected') || '';
      const placeholder = districtSelect.getAttribute('data-placeholder') || '';

      districtSelect.innerHTML = '';
      if (placeholder) {
        const emptyOption = document.createElement('option');
        emptyOption.value = '';
        emptyOption.textContent = placeholder;
        districtSelect.appendChild(emptyOption);
      }
      districts.forEach((d) => {
        const option = document.createElement('option');
        option.value = d;
        option.textContent = d;
        districtSelect.appendChild(option);
      });

      if (current && districts.includes(current)) {
        districtSelect.value = current;
      } else if (placeholder) {
        districtSelect.value = '';
      }
    };

    fillDistricts();
    provinceSelect.addEventListener('change', fillDistricts);
  }

  function setupMagneticButtons() {
    const buttons = document.querySelectorAll('.btn-lux, .btn-glow, .btn-chat, .dock-btn, .btn-edit, .btn-delete');
    buttons.forEach((btn) => {
      btn.addEventListener('mousemove', (e) => {
        const rect = btn.getBoundingClientRect();
        const x = (e.clientX - rect.left - rect.width / 2) / rect.width;
        const y = (e.clientY - rect.top - rect.height / 2) / rect.height;
        btn.style.transform = `translate(${x * 5}px, ${y * 5}px)`;
      });

      btn.addEventListener('mouseleave', () => {
        btn.style.transform = '';
      });
    });
  }

  function setupParallax() {
    const items = document.querySelectorAll('[data-parallax]');
    if (!items.length) return;

    let ticking = false;
    const update = () => {
      const y = window.scrollY;
      items.forEach((el) => {
        const speed = Number(el.getAttribute('data-parallax') || 0);
        const offset = Math.round(y * speed);
        el.style.transform = `translate3d(0, ${offset}px, 0) scale(1.05)`;
      });
      ticking = false;
    };

    window.addEventListener('scroll', () => {
      if (!ticking) {
        window.requestAnimationFrame(update);
        ticking = true;
      }
    }, { passive: true });

    update();
  }

  function setupCounters() {
    const counters = document.querySelectorAll('[data-count-to]');
    if (!counters.length) return;

    const animate = (el) => {
      const target = Number(el.getAttribute('data-count-to') || '0');
      if (Number.isNaN(target)) return;

      const hasPercent = el.textContent.trim().startsWith('%');
      const duration = 900;
      const start = performance.now();
      const decimals = target % 1 === 0 ? 0 : 1;

      const step = (now) => {
        const progress = Math.min(1, (now - start) / duration);
        const value = target * (1 - Math.pow(1 - progress, 3));
        const formatted = value.toLocaleString('tr-TR', {
          minimumFractionDigits: decimals,
          maximumFractionDigits: decimals
        });

        el.textContent = `${hasPercent ? '%' : ''}${formatted}`;
        if (progress < 1) requestAnimationFrame(step);
      };

      requestAnimationFrame(step);
    };

    const io = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        animate(entry.target);
        io.unobserve(entry.target);
      });
    }, { threshold: 0.45 });

    counters.forEach((c) => io.observe(c));
  }

  function prepareCanvas(canvas) {
    const rect = canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    const width = Math.max(120, Math.floor(rect.width));
    const height = Math.max(120, Math.floor(rect.height));

    canvas.width = Math.floor(width * dpr);
    canvas.height = Math.floor(height * dpr);

    const ctx = canvas.getContext('2d');
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return { ctx, width, height };
  }

  function drawDonut(canvas, values, colors, labels, title) {
    if (!canvas) return;

    const { ctx, width, height } = prepareCanvas(canvas);
    if (!values.some((value) => Number(value) > 0)) {
      values = [1, 0];
      colors = ['rgba(120,210,222,0.42)', 'rgba(255,255,255,0.08)'];
      labels = ['Veri bekleniyor', ''];
    }
    const total = values.reduce((a, b) => a + b, 0) || 1;
    const cx = width * 0.28;
    const cy = height * 0.5;
    const radius = Math.min(width, height) * 0.26;
    const line = radius * 0.42;

    let start = -Math.PI / 2;

    values.forEach((value, i) => {
      const angle = (value / total) * Math.PI * 2;
      ctx.beginPath();
      ctx.lineWidth = line;
      ctx.strokeStyle = colors[i];
      ctx.arc(cx, cy, radius, start, start + angle);
      ctx.stroke();
      start += angle;
    });

    ctx.fillStyle = '#f4f8ff';
    ctx.font = '700 24px Manrope';
    ctx.textAlign = 'center';
    ctx.fillText(String(total), cx, cy + 6);

    ctx.fillStyle = '#9fb0c8';
    ctx.font = '500 11px Manrope';
    ctx.fillText(title, cx, cy + 24);

    const legendX = width * 0.56;
    let legendY = 30;

    labels.forEach((label, i) => {
      ctx.fillStyle = colors[i];
      ctx.fillRect(legendX, legendY - 9, 11, 11);
      ctx.fillStyle = '#dbe5f7';
      ctx.font = '600 12px Manrope';
      ctx.textAlign = 'left';
      ctx.fillText(`${label}: ${values[i]}`, legendX + 18, legendY);
      legendY += 24;
    });
  }

  function drawBars(canvas, labels, values, color) {
    if (!canvas) return;

    const { ctx, width, height } = prepareCanvas(canvas);
    if (!Array.isArray(labels) || !labels.length || !values.some((value) => Number(value) > 0)) {
      labels = ['Veri yok'];
      values = [1];
      color = 'rgba(120,210,222,0.48)';
    }
    const gap = 12;
    const top = 24;
    const bottom = 32;
    const chartHeight = height - top - bottom;
    const chartWidth = width - 20;
    const max = Math.max(1, ...values);
    const count = Math.max(labels.length, 1);
    const barWidth = (chartWidth - gap * (count + 1)) / count;

    ctx.fillStyle = 'rgba(255,255,255,0.09)';
    ctx.fillRect(10, height - bottom, chartWidth, 1);

    labels.forEach((label, i) => {
      const x = 10 + gap + i * (barWidth + gap);
      const barH = (values[i] / max) * (chartHeight - 6);
      const y = top + (chartHeight - barH);

      const grad = ctx.createLinearGradient(0, y, 0, y + barH);
      grad.addColorStop(0, color);
      grad.addColorStop(1, 'rgba(255,255,255,0.14)');

      ctx.fillStyle = grad;
      ctx.fillRect(x, y, barWidth, barH);

      ctx.fillStyle = '#e6eefc';
      ctx.font = '700 11px Manrope';
      ctx.textAlign = 'center';
      ctx.fillText(labels.length === 1 && labels[0] === 'Veri yok' ? '-' : String(values[i]), x + barWidth / 2, y - 6);

      ctx.fillStyle = '#9fb0c8';
      ctx.font = '500 10px Manrope';
      const clipped = label.length > 10 ? `${label.slice(0, 10)}.` : label;
      ctx.fillText(clipped, x + barWidth / 2, height - 12);
    });
  }

  function setupDashboardCharts() {
    const shell = document.querySelector('.seller-dash-hero[data-dashboard-json], .dashboard-shell[data-dashboard-json]');
    if (!shell) return;

    let data;
    try {
      data = JSON.parse(shell.getAttribute('data-dashboard-json') || '{}');
    } catch {
      data = null;
    }

    if (!data) return;

    drawDonut(
      document.getElementById('rentRatioCanvas'),
      [Number(data.rented || 0), Number(data.active || 0)],
      ['#d6b367', '#78d2de'],
      ['Kiralandi', 'Aktif'],
      'Toplam Ilan'
    );

    drawBars(
      document.getElementById('offerStatusCanvas'),
      ['Beklemede', 'Kabul', 'Red'],
      [Number(data.pending || 0), Number(data.accepted || 0), Number(data.rejected || 0)],
      '#d6b367'
    );

    drawBars(
      document.getElementById('cityDistCanvas'),
      Array.isArray(data.cityLabels) ? data.cityLabels : [],
      Array.isArray(data.cityValues) ? data.cityValues : [],
      '#78d2de'
    );

    drawBars(
      document.getElementById('listingPerfCanvas'),
      Array.isArray(data.listingLabels) ? data.listingLabels : [],
      Array.isArray(data.listingOfferValues) ? data.listingOfferValues : [],
      '#d6b367'
    );

    const redraw = () => {
      drawDonut(
        document.getElementById('rentRatioCanvas'),
        [Number(data.rented || 0), Number(data.active || 0)],
        ['#d6b367', '#78d2de'],
        ['Kiralandi', 'Aktif'],
        'Toplam Ilan'
      );
      drawBars(
        document.getElementById('offerStatusCanvas'),
        ['Beklemede', 'Kabul', 'Red'],
        [Number(data.pending || 0), Number(data.accepted || 0), Number(data.rejected || 0)],
        '#d6b367'
      );
      drawBars(
        document.getElementById('cityDistCanvas'),
        Array.isArray(data.cityLabels) ? data.cityLabels : [],
        Array.isArray(data.cityValues) ? data.cityValues : [],
        '#78d2de'
      );
      drawBars(
        document.getElementById('listingPerfCanvas'),
        Array.isArray(data.listingLabels) ? data.listingLabels : [],
        Array.isArray(data.listingOfferValues) ? data.listingOfferValues : [],
        '#d6b367'
      );
    };

    window.addEventListener('resize', () => {
      window.clearTimeout(window.__evimChartResize);
      window.__evimChartResize = window.setTimeout(redraw, 180);
    });
  }

  function setupStarRatings() {
    document.querySelectorAll('[data-star-group]').forEach((group) => {
      const name = group.getAttribute('data-star-group');
      const input = document.querySelector(`[data-star-value="${name}"]`);
      const buttons = Array.from(group.querySelectorAll('[data-score]'));
      if (!input || !buttons.length) return;

      const paint = (score) => {
        buttons.forEach((button) => {
          button.classList.toggle('active', Number(button.getAttribute('data-score') || 0) <= score);
        });
      };

      buttons.forEach((button) => {
        button.addEventListener('click', () => {
          const score = Number(button.getAttribute('data-score') || 5);
          input.value = String(score);
          paint(score);
        });
      });

      paint(Number(input.value || 5));
    });
  }

  activateNav();
  setupRevealOnScroll();
  setupTiltCards();
  setupHeaderState();
  setupProfileMenu();
  setupDockMenu();
  setupMobileProfileSheet();
  setupDetailedFilter();
  setupImagePreview();
  setupListingSubmitGuard();
  setupLocationSelectors();
  setupMagneticButtons();
  setupParallax();
  setupCounters();
  setupDashboardCharts();
  setupStarRatings();

  body.classList.add('js-ready');
})();
