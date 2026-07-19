(() => {
  const stillEl = document.getElementById("still");
  const clipEl = document.getElementById("clip");
  const slugEl = document.getElementById("slug");
  const lineEl = document.getElementById("line");
  const supportEl = document.getElementById("support");
  const narrationEl = document.getElementById("narration");
  const brandEl = document.getElementById("brand");
  const disclaimerEl = document.getElementById("disclaimer");
  const progressEl = document.getElementById("progress");
  const btnPlay = document.getElementById("btn-play");
  const btnNext = document.getElementById("btn-next");
  const stage = document.getElementById("stage");

  let manifest = null;
  let index = 0;
  let playing = false;
  let timer = null;
  let startedAt = 0;
  let durationMs = 8000;

  async function load() {
    const res = await fetch("assets/manifest.json", { cache: "no-store" });
    manifest = await res.json();
    if (disclaimerEl && manifest.disclaimer) {
      disclaimerEl.textContent = manifest.disclaimer;
    }
    showShot(0, { preview: true });
  }

  function assetUrl(rel) {
    return rel ? `assets/${rel}` : "";
  }

  function showShot(i, { preview = false } = {}) {
    const shot = manifest.shots[i];
    if (!shot) return;
    index = i;

    slugEl.textContent = shot.slug;
    lineEl.textContent = shot.on_screen;
    supportEl.textContent = shot.support;
    narrationEl.textContent = shot.narration;
    brandEl.style.opacity = i === 0 ? "1" : "0.22";

    stillEl.classList.remove("ken");
    void stillEl.offsetWidth;
    stillEl.src = assetUrl(shot.still);
    stillEl.classList.add("ken");

    const hasClip = Boolean(shot.clip);
    clipEl.hidden = !hasClip;
    stillEl.hidden = false;

    if (hasClip) {
      clipEl.src = assetUrl(shot.clip);
      clipEl.currentTime = 0;
      if (!preview && playing) {
        stillEl.style.opacity = "0";
        clipEl.style.opacity = "1";
        clipEl.play().catch(() => {
          stillEl.style.opacity = "1";
          clipEl.style.opacity = "0";
        });
      } else {
        stillEl.style.opacity = "1";
        clipEl.style.opacity = "0";
        clipEl.pause();
      }
    } else {
      stillEl.style.opacity = "1";
      clipEl.style.opacity = "0";
      clipEl.removeAttribute("src");
      clipEl.load();
    }

    durationMs = (shot.duration_sec || 8) * 1000;
    progressEl.style.width = "0%";
    stage.dataset.shot = shot.id;
  }

  function clearTimer() {
    if (timer) {
      cancelAnimationFrame(timer);
      timer = null;
    }
  }

  function tick() {
    const elapsed = performance.now() - startedAt;
    const p = Math.min(1, elapsed / durationMs);
    progressEl.style.width = `${p * 100}%`;
    if (p >= 1) {
      advance();
      return;
    }
    timer = requestAnimationFrame(tick);
  }

  function advance() {
    clearTimer();
    clipEl.pause();
    if (index >= manifest.shots.length - 1) {
      playing = false;
      btnPlay.hidden = false;
      btnPlay.textContent = "Play again";
      btnNext.hidden = true;
      brandEl.style.opacity = "1";
      narrationEl.textContent = manifest.logline;
      return;
    }
    showShot(index + 1);
    startedAt = performance.now();
    timer = requestAnimationFrame(tick);
  }

  function start() {
    playing = true;
    btnPlay.hidden = true;
    btnNext.hidden = false;
    showShot(0);
    startedAt = performance.now();
    clearTimer();
    timer = requestAnimationFrame(tick);
  }

  btnPlay?.addEventListener("click", start);
  btnNext?.addEventListener("click", () => {
    if (!playing) {
      start();
      return;
    }
    advance();
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === " " || e.key === "Enter") {
      e.preventDefault();
      if (!playing) start();
      else advance();
    }
  });

  load().catch((err) => {
    lineEl.textContent = "Cinematic manifest missing.";
    supportEl.textContent = String(err);
  });
})();
