/*
 * Kalis Track — moteur de rendu de référence des démonstrations (L9, KT-046).
 * Spécification exécutable pour le moteur Flutter du lot L9b. Aucune dépendance.
 *
 * Données : un objet « pose » de poses.json (voir CONTRAT_L9.md §4).
 * Repère : unité = taille du personnage, y vers le haut, sol en y = 0.
 *
 * Cinématique : identique à tools/kinematics.py (angles absolus en degrés ;
 * segments « vers le bas » : 0 = vers le bas, +90 = vers +x ; tronc et cou :
 * 0 = vers le haut, +90 = penché vers +x).
 *
 * Interpolation entre deux images clés A -> B, u ∈ [0, 1] :
 *   1. v = ease(u) avec ease(u) = (1 - cos(π·u)) / 2 (« sinus entrée-sortie ») ;
 *   2. chaque angle : a = A + (B - A)·v (interpolation linéaire des valeurs
 *      stockées, SANS repli modulo 360 : le sens de rotation est porté par les données) ;
 *   3. cinématique directe à partir du bassin ;
 *   4. si A et B partagent le même ancrage (articulation + position), on translate
 *      pour que l'articulation d'ancrage reste exactement sur sa position (mains
 *      sur la barre, pieds au sol) ; sinon le bassin suit A.bassin -> B.bassin avec v.
 * Chronologie : chaque image clé i est tenue `hold` secondes puis la transition
 * i -> i+1 dure `dur` secondes. Boucle « aller-retour » : 0→…→n→…→0 (la transition
 * retour i+1 -> i reprend la durée de i) ; boucle « cycle » : 0→…→n→0 (la dernière
 * transition utilise la durée de n).
 */
(function (root) {
  "use strict";

  var L = {
    tronc: 0.300, epaule_sur_tronc: 0.265, cou: 0.095, bras: 0.180, avant_bras: 0.190,
    cuisse: 0.245, jambe: 0.245, pied_profil: 0.130, pied_face: 0.045,
    demi_epaules_face: 0.120, demi_bassin_face: 0.085
  };
  var HEAD_R = 0.062;
  var KEYS = ["t", "n", "p", "ua_g", "fa_g", "th_g", "sh_g", "ft_g", "ua_d", "fa_d", "th_d", "sh_d", "ft_d"];
  var RAD = Math.PI / 180;

  /* Palettes : 6 couleurs dominantes (L5-C) × 2 modes. Rôles uniquement. */
  var ACCENTS = {
    rouge: { label: "Rouge Kalis", dark: "#E85959", light: "#6B0C0C" },
    jaune: { label: "Jaune", dark: "#F5C400", light: "#7A5800" },
    vert: { label: "Vert", dark: "#4EC08A", light: "#0B4D33" },
    violet: { label: "Violet", dark: "#B38CF2", light: "#44146B" },
    orange: { label: "Orange", dark: "#F2924A", light: "#6E2E05" },
    turquoise: { label: "Turquoise", dark: "#3EC4C4", light: "#08494F" }
  };
  function roles(accentId, mode) {
    var a = ACCENTS[accentId] || ACCENTS.rouge;
    var dark = mode === "sombre";
    return {
      fond: dark ? "#121212" : "#F4F4F4",
      accent: dark ? a.dark : a.light,          // muscles travaillés
      neutre_moyen: "#8A8A8A",                   // corps
      neutre_contraste: dark ? "#F4F4F4" : "#121212" // accessoires et sol
    };
  }

  function down(th, l) { return [Math.sin(th * RAD) * l, -Math.cos(th * RAD) * l]; }
  function up(th, l) { return [Math.sin(th * RAD) * l, Math.cos(th * RAD) * l]; }
  function add(a, b) { return [a[0] + b[0], a[1] + b[1]]; }

  function fk(ang, view, pelvis) {
    var a = {};
    KEYS.forEach(function (k) { a[k] = +(ang[k] || 0); });
    if (ang.n === undefined) a.n = a.t;
    if (ang.p === undefined) a.p = a.t;
    var P = pelvis || [0, 0];
    var J = { bassin: P };
    J.cou = add(P, up(a.t, L.tronc));
    J.tete = add(J.cou, up(a.n, L.cou));
    var sh = add(P, up(a.t, L.epaule_sur_tronc));
    if (view === "face") {
      var px = Math.cos(a.t * RAD), py = -Math.sin(a.t * RAD);
      J.epaule_g = [sh[0] + px * L.demi_epaules_face, sh[1] + py * L.demi_epaules_face];
      J.epaule_d = [sh[0] - px * L.demi_epaules_face, sh[1] - py * L.demi_epaules_face];
      var qx = Math.cos(a.p * RAD), qy = -Math.sin(a.p * RAD);
      J.hanche_g = [P[0] + qx * L.demi_bassin_face, P[1] + qy * L.demi_bassin_face];
      J.hanche_d = [P[0] - qx * L.demi_bassin_face, P[1] - qy * L.demi_bassin_face];
    } else {
      J.epaule_g = J.epaule_d = sh;
      J.hanche_g = J.hanche_d = P;
    }
    ["g", "d"].forEach(function (s) {
      J["coude_" + s] = add(J["epaule_" + s], down(a["ua_" + s], L.bras));
      J["poignet_" + s] = add(J["coude_" + s], down(a["fa_" + s], L.avant_bras));
      J["genou_" + s] = add(J["hanche_" + s], down(a["th_" + s], L.cuisse));
      J["cheville_" + s] = add(J["genou_" + s], down(a["sh_" + s], L.jambe));
      J["pied_" + s] = add(J["cheville_" + s], down(a["ft_" + s], view === "face" ? L.pied_face : L.pied_profil));
    });
    return J;
  }

  function translate(J, dx, dy) {
    var o = {};
    for (var k in J) o[k] = [J[k][0] + dx, J[k][1] + dy];
    return o;
  }

  function ease(u) { return (1 - Math.cos(Math.PI * u)) / 2; }

  function sameAnchor(A, B) {
    return A.anchor.joint === B.anchor.joint &&
      Math.abs(A.anchor.pos[0] - B.anchor.pos[0]) < 1e-6 && Math.abs(A.anchor.pos[1] - B.anchor.pos[1]) < 1e-6;
  }

  /* Pose d'une image clé (positions exactes, recalculées depuis les angles). */
  function poseOf(kf, view) {
    var J = fk(kf.angles, view);
    var an = J[kf.anchor.joint];
    return translate(J, kf.anchor.pos[0] - an[0], kf.anchor.pos[1] - an[1]);
  }

  function interp(A, B, u, view) {
    var v = ease(u), ang = {};
    KEYS.forEach(function (k) {
      var a = A.angles[k] !== undefined ? A.angles[k] : (k === "n" || k === "p" ? A.angles.t : 0);
      var b = B.angles[k] !== undefined ? B.angles[k] : (k === "n" || k === "p" ? B.angles.t : 0);
      ang[k] = a + (b - a) * v;
    });
    if (sameAnchor(A, B)) {
      var J = fk(ang, view), an = J[A.anchor.joint];
      return translate(J, A.anchor.pos[0] - an[0], A.anchor.pos[1] - an[1]);
    }
    var P = [A.pelvis[0] + (B.pelvis[0] - A.pelvis[0]) * v, A.pelvis[1] + (B.pelvis[1] - A.pelvis[1]) * v];
    return fk(ang, view, P);
  }

  /* Séquence de transitions selon le mode de boucle. */
  function timeline(pose) {
    var k = pose.keyframes, n = k.length, steps = [], i;
    if (n === 1) return [{ a: 0, b: 0, hold: k[0].hold || 1, dur: 0 }];
    for (i = 0; i < n - 1; i++) steps.push({ a: i, b: i + 1, hold: k[i].hold, dur: k[i].dur });
    if (pose.loop === "cycle") {
      steps.push({ a: n - 1, b: 0, hold: k[n - 1].hold, dur: k[n - 1].dur });
    } else {
      for (i = n - 1; i > 0; i--) steps.push({ a: i, b: i - 1, hold: k[i].hold, dur: k[i - 1].dur });
    }
    return steps;
  }

  function duration(pose) {
    return timeline(pose).reduce(function (s, x) { return s + x.hold + x.dur; }, 0);
  }

  function jointsAt(pose, t) {
    var steps = timeline(pose), total = duration(pose), k = pose.keyframes;
    if (total <= 0) return poseOf(k[0], pose.view);
    t = ((t % total) + total) % total;
    for (var i = 0; i < steps.length; i++) {
      var s = steps[i];
      if (t < s.hold) return poseOf(k[s.a], pose.view);
      t -= s.hold;
      if (t < s.dur) return interp(k[s.a], k[s.b], t / s.dur, pose.view);
      t -= s.dur;
    }
    return poseOf(k[0], pose.view);
  }

  /* ----- Dessin SVG ----- */
  var SEG = [
    ["cou", "cou", "tete"], ["tronc", "bassin", "cou"],
    ["ceinture_g", "cou", "epaule_g"], ["ceinture_d", "cou", "epaule_d"],
    ["bras_g", "epaule_g", "coude_g"], ["bras_d", "epaule_d", "coude_d"],
    ["avant_bras_g", "coude_g", "poignet_g"], ["avant_bras_d", "coude_d", "poignet_d"],
    ["bassin_g", "bassin", "hanche_g"], ["bassin_d", "bassin", "hanche_d"],
    ["cuisse_g", "hanche_g", "genou_g"], ["cuisse_d", "hanche_d", "genou_d"],
    ["jambe_g", "genou_g", "cheville_g"], ["jambe_d", "genou_d", "cheville_d"],
    ["pied_g", "cheville_g", "pied_g"], ["pied_d", "cheville_d", "pied_d"]
  ];
  var WIDTH = { tronc: 0.075, cou: 0.035, ceinture_g: 0.05, ceinture_d: 0.05, bassin_g: 0.06, bassin_d: 0.06,
    bras_g: 0.042, bras_d: 0.042, avant_bras_g: 0.034, avant_bras_d: 0.034, cuisse_g: 0.055, cuisse_d: 0.055,
    jambe_g: 0.042, jambe_d: 0.042, pied_g: 0.03, pied_d: 0.03 };

  function esc(s) { return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;"); }
  function f(x) { return (Math.round(x * 1000) / 1000).toString(); }
  function line(a, b, w, c, extra) {
    return '<line x1="' + f(a[0]) + '" y1="' + f(-a[1]) + '" x2="' + f(b[0]) + '" y2="' + f(-b[1]) +
      '" stroke="' + c + '" stroke-width="' + f(w) + '" stroke-linecap="round"' + (extra || "") + "/>";
  }
  function circle(p, r, c, fill) {
    return '<circle cx="' + f(p[0]) + '" cy="' + f(-p[1]) + '" r="' + f(r) + '" ' +
      (fill ? 'fill="' + c + '"' : 'fill="none" stroke="' + c + '" stroke-width="0.012"') + "/>";
  }
  function rect(x, y, w, h, c, fill) {
    return '<rect x="' + f(x) + '" y="' + f(-(y + h)) + '" width="' + f(w) + '" height="' + f(h) + '" ' +
      (fill ? 'fill="' + c + '"' : 'fill="none" stroke="' + c + '" stroke-width="0.012"') + "/>";
  }
  function mid(J, a, b) { return [(J[a][0] + J[b][0]) / 2, (J[a][1] + J[b][1]) / 2]; }
  function attachPoint(J, att) {
    if (att === "poignets") return mid(J, "poignet_g", "poignet_d");
    return J[att] || J.poignet_d;
  }

  function drawProps(pose, J, C) {
    var out = "", c = C.neutre_contraste;
    (pose.props || []).forEach(function (p) {
      var t = p.type;
      if (p.static) {
        if (t === "barre_fixe") { out += line([p.x, 0], [p.x, p.y + 0.05], 0.012, c, ' opacity="0.45"') + circle([p.x, p.y], 0.022, c, true); }
        else if (t === "anneaux") { out += line([p.x, p.y + 0.03], [p.x, p.y + 0.55], 0.01, c) + circle([p.x, p.y], 0.035, c, false); }
        else if (t === "barres_paralleles") {
          if (pose.view === "face") { out += circle([p.x - 0.25, p.y], 0.02, c, true) + circle([p.x + 0.25, p.y], 0.02, c, true); }
          else { out += line([p.x - 0.35, p.y], [p.x + 0.35, p.y], 0.028, c) + line([p.x - 0.28, 0], [p.x - 0.28, p.y], 0.02, c) + line([p.x + 0.28, 0], [p.x + 0.28, p.y], 0.02, c); }
        }
        else if (t === "banc") { out += rect(p.x, p.y - 0.035, p.w || 0.4, 0.035, c, true) + line([p.x + 0.04, 0], [p.x + 0.04, p.y - 0.035], 0.02, c) + line([p.x + (p.w || 0.4) - 0.04, 0], [p.x + (p.w || 0.4) - 0.04, p.y - 0.035], 0.02, c); }
        else if (t === "box") { out += rect(p.x, 0, p.w || 0.3, p.h || 0.3, c, false); }
        else if (t === "mur") { out += line([p.x, 0], [p.x, 1.25], 0.02, c); }
        else if (t === "poteau") { out += line([p.x, 0], [p.x, 1.3], 0.03, c); }
        else if (t === "poteau_bas") { out += line([p.x, 0], [p.x, 0.12], 0.03, c); }
        else if (t === "poulie") {
          out += circle([p.x, p.y], 0.03, c, false);
          (p.to || []).forEach(function (j) { out += line([p.x, p.y], J[j], 0.008, c); });
        }
        else if (t === "elastique") { (p.to || []).forEach(function (j) { out += line([p.x, p.y], J[j], 0.012, c, ' stroke-dasharray="0.03 0.02"'); }); }
        else if (t === "machine") { out += rect(p.x - 0.05, 0, 0.1, p.y + 0.5, c, false); }
        else if (t === "banc_incline") { out += line([p.x - 0.1, 0.1], [p.x + 0.45, 0.55], 0.03, c) + line([p.x + 0.2, 0], [p.x + 0.2, 0.35], 0.02, c); }
        else if (t === "cale") { out += rect(p.x - 0.03, 0, 0.06, 0.08, c, true); }
        else if (t === "rameur") { out += line([-0.8, 0.12], [0.35, 0.12], 0.02, c) + rect(0.25, 0, 0.12, 0.3, c, false); }
        else if (t === "velo") { out += circle([0.35, 0.18], 0.16, c, false) + line([0, 0.55], [0.35, 0.18], 0.02, c) + line([0, 0], [0, 0.55], 0.02, c); }
        else if (t === "traineau") {
          out += rect(p.x - 0.12, 0, 0.24, 0.16, c, false) + line([p.x, 0.16], [p.x, 0.75], 0.02, c);
          (p.to || []).forEach(function (j) { out += line([p.x, 0.3], J[j], 0.008, c); });
        }
        else if (t === "battle_rope") {
          (p.to || []).forEach(function (j) {
            var a = J[j];
            out += '<path d="M' + f(a[0]) + " " + f(-a[1]) + " Q " + f((a[0] + p.x) / 2) + " " + f(-(a[1] + 0.25)) + " " + f(p.x) + " " + f(-p.y) + '" fill="none" stroke="' + c + '" stroke-width="0.015"/>';
          });
        }
      } else if (p.between) {
        var a = J[p.between[0]], b = J[p.between[1]];
        if (t === "corde_a_sauter") {
          var low = Math.min(J.pied_g[1], J.pied_d[1]) - 0.03;
          out += '<path d="M' + f(a[0]) + " " + f(-a[1]) + " Q " + f((a[0] + b[0]) / 2 - 0.2) + " " + f(-low + 0.25) + " " + f(b[0]) + " " + f(-b[1]) + '" fill="none" stroke="' + c + '" stroke-width="0.008"/>';
        } else if (t === "elastique") {
          out += line(a, b, 0.012, c, ' stroke-dasharray="0.03 0.02"');
        } else {
          out += line(a, b, 0.018, c);
        }
      } else if (p.attach) {
        var q = attachPoint(J, p.attach);
        var o = p.offset || [0, 0];
        q = [q[0] + o[0], q[1] + o[1]];
        if (t === "barre_chargee") { out += circle(q, 0.11, c, false) + circle(q, 0.02, c, true); }
        else if (t === "halteres") { out += rect(q[0] - 0.05, q[1] - 0.025, 0.1, 0.05, c, true); }
        else if (t === "kettlebell") { out += circle([q[0], q[1] - 0.06], 0.05, c, true); }
        else if (t === "lest") { out += line(J.bassin, [J.bassin[0], J.bassin[1] - 0.12], 0.006, c) + circle([J.bassin[0], J.bassin[1] - 0.16], 0.05, c, true); }
        else if (t === "medecine_ball" || t === "sac_leste") { out += circle(q, 0.07, c, t === "medecine_ball"); }
        else if (t === "roue") { out += circle([q[0], q[1] - 0.02], 0.06, c, false); }
        else if (t === "rouleau") { out += circle([q[0], 0.05], 0.05, c, false); }
        else if (t === "disque") { out += circle(q, 0.08, c, false); }
        else if (t === "gilet") { out += line(mid(J, "bassin", "cou"), J.cou, 0.09, c, ' opacity="0.5"'); }
        else if (t === "elastique_assistance") { out += line([J.poignet_d[0], J.poignet_d[1]], J.pied_d, 0.012, c, ' stroke-dasharray="0.03 0.02"'); }
      }
    });
    return out;
  }

  function drawBody(pose, J, C, highlight) {
    var hl = {};
    (highlight || []).forEach(function (s) { hl[s] = true; });
    var order = pose.view === "face" ? SEG : SEG.filter(function (s) { return /_g$/.test(s[0]); })
      .concat(SEG.filter(function (s) { return !/_[gd]$/.test(s[0]); }))
      .concat(SEG.filter(function (s) { return /_d$/.test(s[0]); }));
    var out = "";
    order.forEach(function (s) {
      var far = pose.view !== "face" && /_g$/.test(s[0]);
      var w = WIDTH[s[0]] || 0.04;
      var op = far ? ' opacity="0.55"' : "";
      out += line(J[s[1]], J[s[2]], w, C.neutre_moyen, op);
      if (hl[s[0].replace(/_[gd]$/, "")] || hl[s[0]]) {
        out += line(J[s[1]], J[s[2]], w * 0.62, C.accent, op);
      }
    });
    out += circle(J.tete, HEAD_R, C.neutre_moyen, true);
    return out;
  }

  function bbox(pose) {
    var xs = [], ys = [];
    pose.keyframes.forEach(function (k) {
      var J = poseOf(k, pose.view);
      for (var j in J) { xs.push(J[j][0]); ys.push(J[j][1]); }
    });
    (pose.props || []).forEach(function (p) {
      if (p.static && p.x !== undefined) { xs.push(p.x); if (p.y !== undefined) ys.push(p.y); }
    });
    ys.push(0);
    var x0 = Math.min.apply(null, xs) - 0.2, x1 = Math.max.apply(null, xs) + 0.2;
    var y0 = -0.06, y1 = Math.max.apply(null, ys) + 0.15;
    var w = Math.max(x1 - x0, 1.1), h = Math.max(y1 - y0, 1.1);
    var cx = (x0 + x1) / 2;
    return [cx - w / 2, -(y0 + h), w, h];
  }

  function svgFor(pose, J, opts) {
    var C = roles(opts.accent, opts.mode);
    var vb = opts.viewBox || bbox(pose);
    var ground = line([vb[0], -0.004], [vb[0] + vb[2], -0.004], 0.008, C.neutre_contraste);
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="' + vb.map(f).join(" ") + '" role="img" aria-label="' +
      esc(opts.label || "démonstration") + '">' + (opts.background !== false ? '<rect x="' + f(vb[0]) + '" y="' + f(vb[1]) +
      '" width="' + f(vb[2]) + '" height="' + f(vb[3]) + '" fill="' + C.fond + '"/>' : "") +
      ground + drawProps(pose, J, C) + drawBody(pose, J, C, opts.highlight) + "</svg>";
  }

  /* Lecteur animé. opts : {accent, mode, highlight, label, reduceMotion} */
  function Player(el, pose, opts) {
    this.el = el; this.pose = pose; this.opts = Object.assign({ accent: "rouge", mode: "sombre" }, opts || {});
    this.vb = bbox(pose); this.t = 0; this.raf = null; this.last = null; this.playing = false;
    this.render();
  }
  Player.prototype.render = function () {
    var o = Object.assign({}, this.opts, { viewBox: this.vb });
    if (this.opts.reduceMotion) { this.el.innerHTML = staticStrip(this.pose, o); return; }
    this.el.innerHTML = svgFor(this.pose, jointsAt(this.pose, this.t), o);
  };
  Player.prototype.play = function () {
    if (this.playing || this.opts.reduceMotion) return;
    this.playing = true; this.last = null;
    var self = this;
    function step(ts) {
      if (!self.playing) return;
      if (self.last !== null) self.t += (ts - self.last) / 1000;
      self.last = ts; self.render();
      self.raf = requestAnimationFrame(step);
    }
    this.raf = requestAnimationFrame(step);
  };
  Player.prototype.pause = function () { this.playing = false; if (this.raf) cancelAnimationFrame(this.raf); };
  Player.prototype.set = function (o) { Object.assign(this.opts, o); this.render(); };
  Player.prototype.destroy = function () { this.pause(); this.el.innerHTML = ""; };

  /* Version statique (réduction des animations) : images clés côte à côte. */
  function staticStrip(pose, opts) {
    var vb = opts.viewBox || bbox(pose);
    var parts = pose.keyframes.map(function (k, i) {
      var J = poseOf(k, pose.view);
      var svg = svgFor(pose, J, Object.assign({}, opts, { viewBox: vb, label: (opts.label || "") + " — " + k.label }));
      return '<figure class="kt-kf"><div class="kt-kf-svg">' + svg + '</div><figcaption>' + (i + 1) + ". " + esc(k.label) + "</figcaption></figure>";
    });
    return '<div class="kt-strip">' + parts.join("") + "</div>";
  }

  var api = { L: L, HEAD_R: HEAD_R, fk: fk, poseOf: poseOf, interp: interp, ease: ease, timeline: timeline,
    duration: duration, jointsAt: jointsAt, svgFor: svgFor, staticStrip: staticStrip, bbox: bbox,
    roles: roles, ACCENTS: ACCENTS, Player: Player };
  root.KTPose = api;
  if (typeof module !== "undefined" && module.exports) module.exports = api;
})(typeof window !== "undefined" ? window : globalThis);
