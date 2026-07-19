const BLOCKS = [
  {
    id: "1 · C01 Drone canopy",
    body: "Weather window first. Aspen sea as one body (Single Tree). Subtle shared sway — no wildlife harassment.",
  },
  {
    id: "2 · D01–D02 Lot ritual",
    body: "Golden-hour parking lot: tripods, faces tilting up as the craft lifts (Leaf-Peeping Eschaton).",
  },
  {
    id: "3 · B02 Unison turn",
    body: "Overlook, locked-off. Three calm hikers turn to camera on one clap (High Consensus).",
  },
  {
    id: "4 · C03 + G01–G03 Extract",
    body: "Graft + Popper macros: bright light, tweezers, prosthetic ulcer, pull, hold the hole — second thread creeps in. Prosthetics only.",
  },
  {
    id: "5 · G05 Sleep webs / trees",
    body: "Dark room: yank-web to lens + aspen tips through sheet. Hallucination cash-out.",
  },
  {
    id: "6 · A01–A04 Valley airlock",
    body: "When alpine light dies: clinic/visitor doorway, redactions, inventory + GOLD memory card.",
  },
];

const root = document.getElementById("slates");
for (const b of BLOCKS) {
  const el = document.createElement("article");
  el.className = "slate";
  el.innerHTML = `<strong>${b.id}</strong><span>${b.body}</span>`;
  root.appendChild(el);
}
