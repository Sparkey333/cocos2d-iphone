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
    id: "4 · C03 Graft macro",
    body: "Root-silk thread + gel on sleeve/appliance against bark. Hold like The Fly.",
  },
  {
    id: "5 · A01–A04 Valley airlock",
    body: "When alpine light dies: clinic/visitor doorway, redactions, inventory + GOLD memory card.",
  },
  {
    id: "Blocks A–F",
    body: "Airlock · Consensus · Single Tree · Leaf-peeping · Treeline fork · Safe granite. Full tables in DIRECTOR_BRIEF.md.",
  },
];

const root = document.getElementById("slates");
for (const b of BLOCKS) {
  const el = document.createElement("article");
  el.className = "slate";
  el.innerHTML = `<strong>${b.id}</strong><span>${b.body}</span>`;
  root.appendChild(el);
}
