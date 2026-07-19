const BLOCKS = [
  {
    id: "A — Intake Clinic",
    body: "Doorway enter, empty chair, white coat exit, redacted clipboard, inventory hero macros. Pocket 3. RE hub language.",
  },
  {
    id: "B — The Joined",
    body: "Idle fruiting sway, Chorus pulse turn, many-angle hallway approach on metronome. Fungal group mind — sync, don’t sprint.",
  },
  {
    id: "C — Quarantine Flood",
    body: "Plastic cathedral, Action-cam wade, filaments on barrier tape, loudspeaker lie plate for ADR.",
  },
  {
    id: "D — The Fly Lab",
    body: "Confession push-in, practical filament from appliance/gel (never real wound), resin sweat macro, sealed booth telefusion anxiety.",
  },
  {
    id: "E — Aspen / Chorus",
    body: "Legal drone over pale trees, fruiting through vents, vein tunnel move, unison exhale ending.",
  },
  {
    id: "F — Safe Room",
    body: "Dictaphone save ritual, map scribble, 15 seconds of shoulders dropping. Let the game breathe.",
  },
];

const root = document.getElementById("slates");
for (const b of BLOCKS) {
  const el = document.createElement("article");
  el.className = "slate";
  el.innerHTML = `<strong>${b.id}</strong><span>${b.body}</span>`;
  root.appendChild(el);
}
