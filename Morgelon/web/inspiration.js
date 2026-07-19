(() => {
  const grid = document.getElementById("grid");
  const status = document.getElementById("status");

  const isVideo = (path) =>
    /\.(mp4|mov|m4v|webm|mkv|avi)$/i.test(path || "");

  async function load() {
    try {
      const res = await fetch("assets/inspiration/gallery.json", { cache: "no-store" });
      if (!res.ok) throw new Error("No gallery yet");
      const data = await res.json();
      status.textContent = `${data.count || 0} plate(s) imported · sources: Drive / Photos Picker / inbox / rclone`;
      grid.innerHTML = "";
      for (const item of data.items || []) {
        const card = document.createElement("article");
        card.className = "insp-card";
        const src = `assets/inspiration/${item.path}`;
        if (isVideo(item.path)) {
          const v = document.createElement("video");
          v.src = src;
          v.muted = true;
          v.loop = true;
          v.playsInline = true;
          v.addEventListener("mouseenter", () => v.play().catch(() => {}));
          v.addEventListener("mouseleave", () => {
            v.pause();
            v.currentTime = 0;
          });
          card.appendChild(v);
        } else {
          const img = document.createElement("img");
          img.src = src;
          img.alt = item.meta?.filename || item.id;
          img.loading = "lazy";
          card.appendChild(img);
        }
        const label = document.createElement("span");
        label.textContent = item.source || "import";
        card.appendChild(label);
        grid.appendChild(card);
      }
      if (!(data.items || []).length) {
        status.textContent =
          "Gallery empty. From Morgelon/bridge: python -m morgelon_bridge auth && python -m morgelon_bridge sync && python -m morgelon_bridge photos";
      }
    } catch {
      status.textContent =
        "No inspiration gallery yet. Set up OAuth in Morgelon/bridge (see README), then run sync / photos.";
    }
  }

  load();
})();
