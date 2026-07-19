(() => {
  const state = {
    threads: 3,
    evidence: 0,
    denial: 0,
    bloom: 12,
    power: 0,
    vaccineUnknown: true,
    lastLie: "There is nothing in your skin.",
  };

  const screens = [...document.querySelectorAll(".screen")];
  const bodyMeter = document.getElementById("body-meter");
  const aspenMeter = document.getElementById("aspen-meter");
  const threadStage = document.getElementById("thread-stage");
  const clinicCopy = document.getElementById("clinic-copy");
  const floodCopy = document.getElementById("flood-copy");
  const aspenHeadline = document.getElementById("aspen-headline");
  const aspenCopy = document.getElementById("aspen-copy");
  const canvas = document.getElementById("veins");
  const ctx = canvas.getContext("2d");

  function meterText() {
    return `Threads ${state.threads} · Bloom ${state.bloom}% · Evidence ${state.evidence} · Denial ${state.denial} · Power ${state.power}`;
  }

  function refreshMeters() {
    if (bodyMeter) bodyMeter.textContent = meterText();
    if (aspenMeter) aspenMeter.textContent = meterText();
  }

  function hasAscended() {
    return (state.evidence >= 4 && state.power >= 5) || state.bloom >= 80;
  }

  function showScreen(name) {
    screens.forEach((screen) => {
      const match = screen.dataset.screen === name;
      screen.classList.toggle("active", match);
      screen.hidden = !match;
    });

    document.body.classList.toggle("mode-clinic", name === "clinic");

    if (name === "aspen") {
      renderAspenEnding();
    }
    refreshMeters();
  }

  function pullThread() {
    state.threads += 1;
    state.bloom = Math.min(100, state.bloom + 7);
    state.evidence += 1;
    state.power += 1;
    state.lastLie = "Fiber matches no textile catalog.";
    spawnThreadVisual();
    // Satisfying disgust: the pull spawns more thread at the edge
    if (state.bloom >= 40) spawnThreadVisual();
    if (state.bloom >= 70) spawnThreadVisual();
    const status = document.querySelector("#screen-body .support");
    if (status) {
      if (state.bloom >= 70) {
        status.textContent =
          "Too good. Now the images lie worse — worms in the blood, webs shooting in the dark, aspens cropping up in sleep. Still itching.";
      } else if (state.bloom >= 40) {
        status.textContent =
          "Relief for one second. Another filament climbs the sore while you watch. Satisfying. Disgusting.";
      } else {
        status.textContent =
          "Ulcer edge. String. The tweezers tick. Always itching.";
      }
    }
    refreshMeters();
  }

  function spawnThreadVisual() {
    if (!threadStage) return;
    const el = document.createElement("span");
    el.className = "thread";
    const top = 12 + Math.random() * 56;
    const len = 45 + Math.random() * 45;
    const rot = -8 + Math.random() * 16;
    el.style.top = `${top}%`;
    el.style.setProperty("--len", `${len}%`);
    el.style.transform = `rotate(${rot}deg)`;
    threadStage.appendChild(el);
    if (threadStage.children.length > 12) {
      threadStage.removeChild(threadStage.firstChild);
    }
  }

  function renderAspenEnding() {
    const ascended = hasAscended();
    aspenHeadline.textContent = ascended
      ? "The appearance of mischief is evidence enough with power."
      : "Aspens in your blood.";
    aspenCopy.textContent = ascended
      ? "Trees grow through the venous dark — pale trunks, quivering leaves, a forest that learned your pulse. They called you crazy. The filaments kept the minutes."
      : "Roots tap the marrow. Pale trunks behind the eyes. You still need more thread, more zone, more proof before mischief hardens into power.";
  }

  function reset() {
    state.threads = 3;
    state.evidence = 0;
    state.denial = 0;
    state.bloom = 12;
    state.power = 0;
    state.vaccineUnknown = true;
    state.lastLie = "There is nothing in your skin.";
    if (threadStage) threadStage.innerHTML = "";
    clinicCopy.textContent =
      "They do not look at the thread between your fingers. They look at the door.";
    floodCopy.textContent =
      "Plastic sheeting breathes. Sirens rewrite the shoreline. Your name is a rumor with a stamp.";
    showScreen("title");
  }

  document.querySelectorAll("[data-go]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const dest = btn.getAttribute("data-go");
      if (dest === "body") {
        state.denial += 1;
        state.bloom = Math.min(100, state.bloom + 5);
      }
      showScreen(dest);
    });
  });

  document.getElementById("btn-insist")?.addEventListener("click", () => {
    state.denial += 1;
    state.evidence += 1;
    state.power += 1;
    state.bloom = Math.min(100, state.bloom + 5);
    state.lastLie = "Sample discarded before lab intake.";
    clinicCopy.textContent =
      "Security will walk you out. Your file says: delusional parasitosis. The thread is still in your hand.";
    refreshMeters();
  });

  document.getElementById("btn-pull")?.addEventListener("click", pullThread);

  document.getElementById("btn-wade")?.addEventListener("click", () => {
    state.denial += 2;
    state.bloom = Math.min(100, state.bloom + 9);
    state.evidence += 1;
    state.power += 1;
    state.lastLie = "The zone was never contaminated.";
    floodCopy.textContent =
      "Lies rise faster than water. Barricades print tomorrow's innocence while the current keeps your shoes.";
    refreshMeters();
  });

  document.getElementById("btn-vax")?.addEventListener("click", () => {
    state.vaccineUnknown = true;
    state.evidence += 1;
    state.power += 1;
    floodCopy.textContent =
      "Vaccine?? No one knows. Batch codes blacked out. The clipboard smiles without answering.";
    refreshMeters();
  });

  document.getElementById("btn-again")?.addEventListener("click", reset);

  // Vein / aspen canopy background
  let width = 0;
  let height = 0;
  let t = 0;
  const branches = [];

  function resize() {
    width = canvas.width = window.innerWidth * devicePixelRatio;
    height = canvas.height = window.innerHeight * devicePixelRatio;
    canvas.style.width = `${window.innerWidth}px`;
    canvas.style.height = `${window.innerHeight}px`;
    seedBranches();
  }

  function seedBranches() {
    branches.length = 0;
    const count = Math.max(10, Math.floor(window.innerWidth / 90));
    for (let i = 0; i < count; i++) {
      branches.push({
        x: Math.random() * width,
        y: height * (0.55 + Math.random() * 0.45),
        lean: -0.4 + Math.random() * 0.8,
        depth: 0.35 + Math.random() * 0.65,
        phase: Math.random() * Math.PI * 2,
      });
    }
  }

  function drawBranch(x, y, angle, len, depth, phase) {
    if (depth <= 0 || len < 6 * devicePixelRatio) return;
    const nx = x + Math.cos(angle) * len;
    const ny = y + Math.sin(angle) * len;
    const pulse = 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(t * 0.8 + phase));
    ctx.strokeStyle = `rgba(184, 224, 106, ${0.08 + depth * 0.12 * pulse})`;
    ctx.lineWidth = Math.max(0.6, depth * 1.8 * devicePixelRatio);
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(nx, ny);
    ctx.stroke();

    // blood-thread underlayer
    ctx.strokeStyle = `rgba(139, 46, 46, ${0.04 + depth * 0.08})`;
    ctx.lineWidth = Math.max(0.4, depth * devicePixelRatio);
    ctx.beginPath();
    ctx.moveTo(x + 1, y);
    ctx.lineTo(nx + 1, ny);
    ctx.stroke();

    const sway = Math.sin(t * 0.6 + phase) * 0.08;
    drawBranch(nx, ny, angle - 0.45 + sway, len * 0.72, depth - 1, phase + 0.4);
    drawBranch(nx, ny, angle + 0.5 + sway * 0.5, len * 0.68, depth - 1, phase + 0.7);
  }

  function frame() {
    t += 0.016;
    ctx.clearRect(0, 0, width, height);
    for (const b of branches) {
      const bloomBoost = 1 + state.bloom / 120;
      drawBranch(
        b.x,
        b.y,
        -Math.PI / 2 + b.lean + Math.sin(t * 0.35 + b.phase) * 0.05,
        (40 + b.depth * 50) * devicePixelRatio * bloomBoost,
        5,
        b.phase
      );
    }
    requestAnimationFrame(frame);
  }

  window.addEventListener("resize", resize);
  resize();
  refreshMeters();
  requestAnimationFrame(frame);

  const boot = new URLSearchParams(location.search).get("screen") || (location.hash || "").replace("#", "");
  if (boot && ["title", "clinic", "body", "flood", "aspen"].includes(boot)) {
    if (boot !== "title") {
      // Seed a mid-run state so meters / ending read as lived-in.
      state.threads = 6;
      state.evidence = 4;
      state.denial = 3;
      state.bloom = 48;
      state.power = 5;
      for (let i = 0; i < 4; i++) spawnThreadVisual();
    }
    showScreen(boot);
  }
})();
