/*
 * Kalis Track — moteur de rendu de référence des démonstrations, version 2.0.0 (L9R, KT-046).
 * Spécification exécutable pour le moteur Flutter du lot L9b. Aucune dépendance.
 *
 * Données : un gabarit de poses.json v2 (« gabarits »), et pour un exercice la liste
 * des muscles à mettre en évidence (poses.json « exercices » → muscles.primaires / secondaires).
 *
 * Repère : unité = taille du personnage, y vers le haut, sol en y = 0 ; profil : le
 * personnage regarde vers +x ; face : +x = côté gauche du personnage.
 *
 * Cinématique : angles ABSOLUS de segment en degrés, identiques à tools/body_model.py :
 *   segments « vers le bas » (ua bras, fa avant-bras, ha main, th cuisse, sh jambe) :
 *   0 = vers le bas, +90 = vers +x ; tronc t et cou n : 0 = vers le haut, +90 = vers +x ;
 *   ft = direction talon -> pointe (même convention « vers le bas », pied à plat = +90).
 *   Longueurs (Drillis & Contini) : voir L.
 *
 * Interpolation entre deux images clés A -> B, u ∈ [0, 1] :
 *   1. v = (1 − cos(π·u)) / 2 ;
 *   2. chaque angle : a = A + (B − A)·v (linéaire, SANS repli modulo 360) ;
 *   3. cinématique directe depuis le bassin ;
 *   4. même ancrage (articulation + position) sur A et B : translation pour garder
 *      l'articulation d'ancrage sur sa position ; sinon le bassin suit A.pelvis -> B.pelvis.
 * Chronologie : image i tenue `hold` s puis transition `dur` s ; boucle « aller-retour »
 * 0→…→n→…→0 (retour i+1→i avec la durée de i) ; « cycle » 0→…→n→0 (dernière transition : durée de n).
 *
 * Silhouette : formes pleines (aplats, sans dégradé) construites à partir des articulations :
 * tronc = polygone dans le repère du tronc (profil) ou trapèze épaules-bassin (face) ;
 * membres = capsules effilées ; tête = disque ; mains = capsules ; pieds = polygones talon-pointe.
 * Zones de mise en évidence = moitiés antérieure / postérieure des capsules et régions du
 * tronc (voir ZONES et MUSCLE_ZONE) ; rôles de couleur : corps = neutre moyen, primaire =
 * accent, secondaire = accent atténué (opacité 0,45), accessoires et sol = neutre contrasté.
 */
(function (root) {
  "use strict";

  var L = {
    tronc: 0.288, cou: 0.110, bras: 0.186, avant_bras: 0.146, main: 0.108, prise: 0.050,
    cuisse: 0.245, jambe: 0.246, pied_talon: 0.045, pied_pointe: 0.107, pied_hauteur: 0.039,
    demi_epaules_face: 0.130, demi_bassin_face: 0.095
  };
  var HEAD_R = 0.065;
  var WIDTH = { bras: [0.052, 0.040], avant_bras: [0.040, 0.028], main: [0.026, 0.020],
    cuisse: [0.082, 0.052], jambe: [0.054, 0.030], cou: [0.045, 0.045] };
  var KEYS = ["t", "n", "p", "ua_g", "fa_g", "ha_g", "th_g", "sh_g", "ft_g", "ua_d", "fa_d", "ha_d", "th_d", "sh_d", "ft_d"];
  var RAD = Math.PI / 180;

  /* Palettes : 6 couleurs dominantes (L5-C, lib/app_theme.dart) × 2 modes. Rôles uniquement. */
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
      accent: dark ? a.dark : a.light,                 // muscles primaires
      neutre_moyen: "#8A8A8A",                          // corps (KPalette.gray)
      neutre_moyen_loin: dark ? "#5E5E5E" : "#B4B4B4",  // membres du côté éloigné (profil)
      neutre_contraste: dark ? "#F4F4F4" : "#121212"    // accessoires et sol
    };
  }

  function down(th, l) { return [Math.sin(th * RAD) * l, -Math.cos(th * RAD) * l]; }
  function up(th, l) { return [Math.sin(th * RAD) * l, Math.cos(th * RAD) * l]; }
  function add(a, b) { return [a[0] + b[0], a[1] + b[1]]; }
  function sub(a, b) { return [a[0] - b[0], a[1] - b[1]]; }
  function mul(a, k) { return [a[0] * k, a[1] * k]; }
  function norm(a) { var l = Math.hypot(a[0], a[1]) || 1; return [a[0] / l, a[1] / l]; }
  function perp(a) { return [-a[1], a[0]]; } // rotation +90° (sens trigonométrique, y vers le haut)

  function fk(ang, view, pelvis) {
    var a = {};
    KEYS.forEach(function (k) { a[k] = +(ang[k] || 0); });
    if (ang.n === undefined) a.n = a.t;
    if (ang.p === undefined) a.p = a.t;
    var P = pelvis || [0, 0];
    var J = { bassin: P };
    J.cou = add(P, up(a.t, L.tronc));
    J.tete = add(J.cou, up(a.n, L.cou));
    if (view === "face") {
      var px = Math.cos(a.t * RAD), py = -Math.sin(a.t * RAD);
      J.epaule_g = [J.cou[0] + px * L.demi_epaules_face, J.cou[1] + py * L.demi_epaules_face];
      J.epaule_d = [J.cou[0] - px * L.demi_epaules_face, J.cou[1] - py * L.demi_epaules_face];
      var qx = Math.cos(a.p * RAD), qy = -Math.sin(a.p * RAD);
      J.hanche_g = [P[0] + qx * L.demi_bassin_face, P[1] + qy * L.demi_bassin_face];
      J.hanche_d = [P[0] - qx * L.demi_bassin_face, P[1] - qy * L.demi_bassin_face];
    } else {
      J.epaule_g = J.epaule_d = J.cou;
      J.hanche_g = J.hanche_d = P;
    }
    ["g", "d"].forEach(function (s) {
      J["coude_" + s] = add(J["epaule_" + s], down(a["ua_" + s], L.bras));
      J["poignet_" + s] = add(J["coude_" + s], down(a["fa_" + s], L.avant_bras));
      J["main_" + s] = add(J["poignet_" + s], down(a["ha_" + s], L.main));
      J["prise_" + s] = add(J["poignet_" + s], down(a["ha_" + s], L.prise));
      J["genou_" + s] = add(J["hanche_" + s], down(a["th_" + s], L.cuisse));
      J["cheville_" + s] = add(J["genou_" + s], down(a["sh_" + s], L.jambe));
      if (view === "face") {
        J["pied_" + s] = add(J["cheville_" + s], down(a["sh_" + s], L.pied_hauteur));
        J["talon_" + s] = J["cheville_" + s];
      } else {
        var sole = down(a["ft_" + s], 1), pp = [sole[1], -sole[0]];   // normale de la plante vers le bas
        var base = add(J["cheville_" + s], mul(pp, L.pied_hauteur));
        J["talon_" + s] = sub(base, mul(sole, L.pied_talon));
        J["pied_" + s] = add(base, mul(sole, L.pied_pointe));
      }
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
  function timeline(pose) {
    var k = pose.keyframes, n = k.length, steps = [], i;
    if (n === 1) return [{ a: 0, b: 0, hold: k[0].hold || 1, dur: 0 }];
    for (i = 0; i < n - 1; i++) steps.push({ a: i, b: i + 1, hold: k[i].hold, dur: k[i].dur });
    if (pose.loop === "cycle") steps.push({ a: n - 1, b: 0, hold: k[n - 1].hold, dur: k[n - 1].dur });
    else for (i = n - 1; i > 0; i--) steps.push({ a: i, b: i - 1, hold: k[i].hold, dur: k[i - 1].dur });
    return steps;
  }
  function duration(pose) { return timeline(pose).reduce(function (s, x) { return s + x.hold + x.dur; }, 0); }
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

  /* ----- Zones de mise en évidence ----- */
  var MUSCLE_ZONE = {
    // tronc avant
    grand_pectoral_claviculaire: ["poitrine"], grand_pectoral_sterno_costal: ["poitrine"], grand_pectoral_abdominal: ["poitrine"],
    petit_pectoral: ["poitrine"], dentele_anterieur: ["poitrine"], coraco_brachial: ["bras_avant"],
    droit_abdomen: ["abdomen"], oblique_externe: ["abdomen"], oblique_interne: ["abdomen"], transverse_abdomen: ["abdomen"],
    diaphragme: ["abdomen"], plancher_pelvien: ["abdomen"], grand_psoas: ["abdomen", "cuisse_avant"], iliaque: ["abdomen", "cuisse_avant"],
    // tronc arrière
    trapeze_superieur: ["cou_arriere", "haut_dos"], trapeze_moyen: ["haut_dos"], trapeze_inferieur: ["haut_dos"],
    rhomboides: ["haut_dos"], elevateur_scapula: ["cou_arriere"], grand_dorsal: ["haut_dos", "bas_dos"], grand_rond: ["haut_dos"],
    erecteurs_thoraciques: ["haut_dos"], erecteurs_lombaires: ["bas_dos"], multifides: ["bas_dos"], carre_des_lombes: ["bas_dos"],
    extenseurs_cervicaux: ["cou_arriere"], sterno_cleido_mastoidien: ["cou_avant"], flechisseurs_cervicaux_profonds: ["cou_avant"],
    // épaule et bras
    deltoide_anterieur: ["epaule"], deltoide_moyen: ["epaule"], deltoide_posterieur: ["epaule"],
    supra_epineux: ["epaule"], infra_epineux: ["epaule"], petit_rond: ["epaule"], sous_scapulaire: ["epaule"],
    biceps_chef_long: ["bras_avant"], biceps_chef_court: ["bras_avant"], brachial: ["bras_avant"],
    triceps_chef_long: ["bras_arriere"], triceps_chef_lateral: ["bras_arriere"], triceps_chef_medial: ["bras_arriere"], ancone: ["bras_arriere"],
    brachio_radial: ["avant_bras_avant"], flechisseurs_du_poignet: ["avant_bras_avant"], flechisseurs_superficiels_des_doigts: ["avant_bras_avant", "main"],
    flechisseurs_profonds_des_doigts: ["avant_bras_avant", "main"], rond_pronateur: ["avant_bras_avant"], carre_pronateur: ["avant_bras_avant"],
    muscles_intrinseques_main: ["main"], extenseurs_du_poignet: ["avant_bras_arriere"], extenseurs_des_doigts: ["avant_bras_arriere"], supinateur: ["avant_bras_arriere"],
    // hanche et cuisse
    grand_fessier: ["fesses"], moyen_fessier: ["fesses"], petit_fessier: ["fesses"], rotateurs_lateraux_hanche: ["fesses"],
    tenseur_fascia_lata: ["cuisse_avant"], sartorius: ["cuisse_avant"], pectine: ["cuisse_avant"], long_adducteur: ["cuisse_avant"],
    court_adducteur: ["cuisse_avant"], grand_adducteur: ["cuisse_arriere"], gracile: ["cuisse_avant"],
    droit_femoral: ["cuisse_avant"], vaste_lateral: ["cuisse_avant"], vaste_medial: ["cuisse_avant"], vaste_intermediaire: ["cuisse_avant"],
    biceps_femoral: ["cuisse_arriere"], biceps_femoral_chef_court: ["cuisse_arriere"], semi_tendineux: ["cuisse_arriere"], semi_membraneux: ["cuisse_arriere"], poplite: ["cuisse_arriere"],
    // jambe
    gastrocnemien_medial: ["jambe_arriere"], gastrocnemien_lateral: ["jambe_arriere"], soleaire: ["jambe_arriere"],
    tibial_posterieur: ["jambe_arriere"], flechisseurs_profonds_des_orteils: ["jambe_arriere"], fibulaires: ["jambe_avant"],
    tibial_anterieur: ["jambe_avant"], long_extenseur_des_orteils: ["jambe_avant"], muscles_intrinseques_pied: ["pied"]
  };
  // zones visibles seulement de face : les autres sont dessinées en contour dans cette vue
  var FACE_FRONT = { poitrine: 1, abdomen: 1, epaule: 1, bras_avant: 1, avant_bras_avant: 1, main: 1, cuisse_avant: 1, jambe_avant: 1, cou_avant: 1 };

  /* ----- Géométrie des formes ----- */
  function f(x) { return (Math.round(x * 1000) / 1000).toString(); }
  function esc(s) { return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;"); }
  function P(pts) { return pts.map(function (p) { return f(p[0]) + " " + f(-p[1]); }).join(" "); }
  function poly(pts, fill, extra) { return '<polygon points="' + P(pts) + '" fill="' + fill + '"' + (extra || "") + "/>"; }
  function arc(center, r, a0, a1, n) {
    var out = [];
    for (var i = 0; i <= n; i++) { var a = a0 + (a1 - a0) * i / n; out.push([center[0] + Math.cos(a) * r, center[1] + Math.sin(a) * r]); }
    return out;
  }
  /* Capsule effilée A -> B (largeurs wa, wb). Retourne {all, front, back} : le côté « front » est
     celui de la normale n = perp(dir) (pour un segment qui descend, c'est +x = l'avant du personnage). */
  function capsule(A, Bp, wa, wb) {
    var d = norm(sub(Bp, A)), n = perp(d), ra = wa / 2, rb = wb / 2;
    var th = Math.atan2(n[1], n[0]);
    var capB = arc(Bp, rb, th, th - Math.PI, 8);       // de +n vers -n en passant par la pointe
    var capA = arc(A, ra, th + Math.PI, th + 2 * Math.PI, 8);
    var all = [add(A, mul(n, ra))].concat(capB, capA);
    var frontPts = [A, add(A, mul(n, ra))].concat(arc(Bp, rb, th, th - Math.PI / 2, 4), [Bp]);
    var backPts = [A, Bp].concat(arc(Bp, rb, th - Math.PI / 2, th - Math.PI, 4), [sub(A, mul(n, ra))]);
    return { all: all, front: frontPts, back: backPts };
  }
  function torsoProfile(J) {
    var P0 = J.bassin, upv = norm(sub(J.cou, J.bassin)), fr = perp(upv); fr = [-fr[0], -fr[1]]; // avant = -perp(up) (= +x debout)
    function pt(u, v) { return add(P0, add(mul(upv, u * L.tronc), mul(fr, v))); }
    var front = [pt(-0.02, 0.055), pt(0.12, 0.08), pt(0.35, 0.09), pt(0.60, 0.115), pt(0.80, 0.125), pt(0.95, 0.10), pt(1.0, 0.06)];
    var back = [pt(1.0, -0.05), pt(0.86, -0.08), pt(0.62, -0.085), pt(0.38, -0.075), pt(0.14, -0.085), pt(-0.02, -0.09), pt(-0.09, -0.045), pt(-0.09, 0.02)];
    var axis = [pt(1.0, 0), pt(0.62, 0), pt(0.5, 0), pt(0.12, 0), pt(-0.09, 0)];
    return {
      all: front.concat(back),
      poitrine: [pt(0.55, 0), pt(0.55, 0.11), pt(0.60, 0.115), pt(0.80, 0.125), pt(0.95, 0.10), pt(1.0, 0.06), pt(1.0, 0)],
      abdomen: [pt(-0.02, 0), pt(-0.02, 0.055), pt(0.12, 0.08), pt(0.35, 0.09), pt(0.55, 0.11), pt(0.55, 0)],
      haut_dos: [pt(1.0, 0), pt(1.0, -0.05), pt(0.86, -0.08), pt(0.62, -0.085), pt(0.5, -0.08), pt(0.5, 0)],
      bas_dos: [pt(0.5, 0), pt(0.5, -0.08), pt(0.38, -0.075), pt(0.14, -0.085), pt(0.12, 0)],
      fesses: [pt(0.12, 0), pt(0.14, -0.085), pt(-0.02, -0.09), pt(-0.09, -0.045), pt(-0.09, 0.02), pt(-0.02, 0.03)]
    };
  }
  function torsoFace(J) {
    var sg = J.epaule_g, sd = J.epaule_d, hg = J.hanche_g, hd = J.hanche_d, c = J.cou, b = J.bassin;
    var upv = norm(sub(c, b)), side = perp(upv); // side = +x debout (gauche du personnage)
    function mixp(a, bb, t) { return [a[0] + (bb[0] - a[0]) * t, a[1] + (bb[1] - a[1]) * t]; }
    var wg = mixp(hg, sg, 0.45), wd = mixp(hd, sd, 0.45);
    var waistG = sub(wg, mul(side, 0.02)), waistD = add(wd, mul(side, 0.02));
    var all = [add(sg, mul(upv, 0.02)), add(sg, mul(side, 0.02)), waistG, add(hg, mul(side, 0.01)), add(hg, mul(upv, -0.05)),
      add(hd, mul(upv, -0.05)), sub(hd, mul(side, 0.01)), waistD, sub(sd, mul(side, 0.02)), add(sd, mul(upv, 0.02))];
    var mid = mixp(b, c, 0.55);
    var mg = mixp(waistG, sg, 0.35), md = mixp(waistD, sd, 0.35);
    return {
      all: all,
      poitrine: [mg, add(sg, mul(side, 0.02)), add(sg, mul(upv, 0.02)), add(sd, mul(upv, 0.02)), sub(sd, mul(side, 0.02)), md],
      abdomen: [add(hg, mul(upv, -0.05)), add(hg, mul(side, 0.01)), waistG, mg, md, waistD, sub(hd, mul(side, 0.01)), add(hd, mul(upv, -0.05))],
      haut_dos: [mg, add(sg, mul(side, 0.02)), add(sd, mul(upv, 0.02)), sub(sd, mul(side, 0.02)), md],
      bas_dos: [waistG, mg, md, waistD], fesses: [add(hg, mul(upv, -0.05)), add(hg, mul(side, 0.01)), sub(hd, mul(side, 0.01)), add(hd, mul(upv, -0.05))]
    };
  }
  function footProfile(J, s) {
    var talon = J["talon_" + s], pointe = J["pied_" + s], ch = J["cheville_" + s];
    var sole = norm(sub(pointe, talon)), upn = perp(sole); // perp(sole) pointe vers le haut quand le pied est à plat (sole = +x -> upn = +y)
    return [talon, pointe, add(pointe, mul(upn, 0.018)), add(add(ch, mul(sole, 0.03)), mul(upn, 0.012)),
      add(sub(ch, mul(sole, 0.02)), mul(upn, 0.01)), add(talon, mul(upn, 0.03))];
  }
  function head(J) {
    return '<circle cx="' + f(J.tete[0]) + '" cy="' + f(-J.tete[1]) + '" r="' + f(HEAD_R) + '"';
  }

  /* Formes du corps : liste de {zone, side, pts, kind} dans l'ordre de dessin. */
  function bodyShapes(pose, J) {
    var view = pose.view, shapes = [];
    function limb(s, far) {
      var a = capsule(J["epaule_" + s], J["coude_" + s], WIDTH.bras[0], WIDTH.bras[1]);
      var fa = capsule(J["coude_" + s], J["poignet_" + s], WIDTH.avant_bras[0], WIDTH.avant_bras[1]);
      var ma = capsule(J["poignet_" + s], J["main_" + s], WIDTH.main[0], WIDTH.main[1]);
      var th = capsule(J["hanche_" + s], J["genou_" + s], WIDTH.cuisse[0], WIDTH.cuisse[1]);
      var sh = capsule(J["genou_" + s], J["cheville_" + s], WIDTH.jambe[0], WIDTH.jambe[1]);
      var out = [];
      out.push({ part: "cuisse", side: s, far: far, all: th.all, zones: { cuisse_avant: th.front, cuisse_arriere: th.back } });
      out.push({ part: "jambe", side: s, far: far, all: sh.all, zones: { jambe_avant: sh.front, jambe_arriere: sh.back } });
      out.push({ part: "pied", side: s, far: far, all: view === "face" ? capsule(J["cheville_" + s], J["pied_" + s], 0.05, 0.05).all : footProfile(J, s), zones: { pied: null } });
      out.push({ part: "bras", side: s, far: far, all: a.all, zones: { bras_avant: a.front, bras_arriere: a.back } });
      out.push({ part: "avant_bras", side: s, far: far, all: fa.all, zones: { avant_bras_avant: fa.front, avant_bras_arriere: fa.back } });
      out.push({ part: "main", side: s, far: far, all: ma.all, zones: { main: null } });
      out.push({ part: "epaule", side: s, far: far, circle: [J["epaule_" + s], 0.048], zones: { epaule: null } });
      return out;
    }
    var torso = view === "face" ? torsoFace(J) : torsoProfile(J);
    var neck = capsule(J.cou, J.tete, WIDTH.cou[0], WIDTH.cou[1]);
    if (view === "face") {
      // ordre : jambes, tronc, cou, tête, bras (devant)
      shapes = shapes.concat(limb("g", false).slice(0, 3), limb("d", false).slice(0, 3));
      shapes.push({ part: "tronc", far: false, all: torso.all, zones: torso });
      shapes.push({ part: "cou", far: false, all: neck.all, zones: { cou_avant: neck.all, cou_arriere: null } });
      shapes.push({ part: "tete", far: false, circle: [J.tete, HEAD_R], zones: {} });
      shapes = shapes.concat(limb("g", false).slice(3), limb("d", false).slice(3));
    } else {
      // profil : côté gauche (éloigné) derrière, puis tronc, cou, tête, puis côté droit (proche) devant
      shapes = shapes.concat(limb("g", true));
      shapes.push({ part: "tronc", far: false, all: torso.all, zones: torso });
      shapes.push({ part: "cou", far: false, all: neck.all, zones: { cou_avant: neck.front, cou_arriere: neck.back } });
      shapes.push({ part: "tete", far: false, circle: [J.tete, HEAD_R], zones: {} });
      shapes = shapes.concat(limb("d", false));
    }
    return shapes;
  }

  function drawBody(pose, J, C, muscles) {
    muscles = muscles || {};
    var prim = {}, sec = {};
    (muscles.primaires || []).forEach(function (m) { (MUSCLE_ZONE[m] || []).forEach(function (z) { prim[z] = true; }); });
    (muscles.secondaires || []).forEach(function (m) { (MUSCLE_ZONE[m] || []).forEach(function (z) { if (!prim[z]) sec[z] = true; }); });
    var out = "";
    bodyShapes(pose, J).forEach(function (sh) {
      var base = sh.far ? C.neutre_moyen_loin : C.neutre_moyen;
      if (sh.circle) out += '<circle cx="' + f(sh.circle[0][0]) + '" cy="' + f(-sh.circle[0][1]) + '" r="' + f(sh.circle[1]) + '" fill="' + base + '"/>';
      else out += poly(sh.all, base);
      var zones = sh.zones || {};
      Object.keys(zones).forEach(function (z) {
        var role = prim[z] ? "prim" : (sec[z] ? "sec" : null);
        if (!role) return;
        var visible = pose.view !== "face" || FACE_FRONT[z];
        var op = (role === "prim" ? 1 : 0.45) * (sh.far ? 0.6 : 1);
        var pts = zones[z];
        if (!visible) {
          // muscle de la face postérieure en vue de face : contour seulement
          if (pts) out += '<polygon points="' + P(pts) + '" fill="none" stroke="' + C.accent + '" stroke-width="0.006" stroke-opacity="' + f(op) + '"/>';
          else if (sh.circle) out += '<circle cx="' + f(sh.circle[0][0]) + '" cy="' + f(-sh.circle[0][1]) + '" r="' + f(sh.circle[1]) + '" fill="none" stroke="' + C.accent + '" stroke-width="0.006" stroke-opacity="' + f(op) + '"/>';
          return;
        }
        if (pts) out += poly(pts, C.accent, ' fill-opacity="' + f(op) + '"');
        else if (sh.circle) out += '<circle cx="' + f(sh.circle[0][0]) + '" cy="' + f(-sh.circle[0][1]) + '" r="' + f(sh.circle[1]) + '" fill="' + C.accent + '" fill-opacity="' + f(op) + '"/>';
        else out += poly(sh.all, C.accent, ' fill-opacity="' + f(op) + '"');
      });
    });
    return out;
  }

  /* ----- Accessoires ----- */
  function line(a, b, w, c, extra) {
    return '<line x1="' + f(a[0]) + '" y1="' + f(-a[1]) + '" x2="' + f(b[0]) + '" y2="' + f(-b[1]) +
      '" stroke="' + c + '" stroke-width="' + f(w) + '" stroke-linecap="round"' + (extra || "") + "/>";
  }
  function circle(p, r, c, fill, extra) {
    return '<circle cx="' + f(p[0]) + '" cy="' + f(-p[1]) + '" r="' + f(r) + '" ' +
      (fill ? 'fill="' + c + '"' : 'fill="none" stroke="' + c + '" stroke-width="0.012"') + (extra || "") + "/>";
  }
  function rect(x, y, w, h, c, fill) {
    return '<rect x="' + f(x) + '" y="' + f(-(y + h)) + '" width="' + f(w) + '" height="' + f(h) + '" ' +
      (fill ? 'fill="' + c + '"' : 'fill="none" stroke="' + c + '" stroke-width="0.012"') + "/>";
  }
  function mid(J, a, b) { return [(J[a][0] + J[b][0]) / 2, (J[a][1] + J[b][1]) / 2]; }
  function attachPoint(J, att) {
    if (att === "prises") return mid(J, "prise_g", "prise_d");
    return J[att] || J.prise_d;
  }
  var PLATE_R = 0.125; // disque de 45 cm pour une taille de 1,80 m

  function drawProps(pose, J, C, layer) {
    var out = "", c = C.neutre_contraste;
    (pose.props || []).forEach(function (p) {
      var t = p.type;
      var behind = p.layer === "arriere";
      if ((layer === "arriere") !== behind) return;
      if (p.static) {
        if (t === "corde") { out += '<rect x="' + f(p.x - 0.022) + '" y="' + f(-(p.y + 0.03)) + '" width="0.044" height="0.10" rx="0.01" fill="' + c + '" fill-opacity="0.35"/>'; }
        else if (t === "barre_fixe") { out += line([p.x - 0.5, 0], [p.x - 0.5, p.y], 0.02, c, ' opacity="0.5"') + line([p.x - 0.5, p.y], [p.x, p.y], 0.012, c, ' opacity="0.5"') + circle([p.x, p.y], 0.022, c, true); }
        else if (t === "anneaux") { out += line([p.x, p.y + 0.03], [p.x, p.y + 0.55], 0.01, c) + circle([p.x, p.y], 0.035, c, false); }
        else if (t === "barres_paralleles") {
          if (pose.view === "face") { out += circle([p.x - 0.25, p.y], 0.02, c, true) + circle([p.x + 0.25, p.y], 0.02, c, true) + line([p.x - 0.25, 0], [p.x - 0.25, p.y], 0.016, c) + line([p.x + 0.25, 0], [p.x + 0.25, p.y], 0.016, c); }
          else { out += line([p.x - 0.28, p.y], [p.x + 0.28, p.y], 0.024, c) + line([p.x - 0.22, 0], [p.x - 0.22, p.y], 0.018, c) + line([p.x + 0.22, 0], [p.x + 0.22, p.y], 0.018, c); }
        }
        else if (t === "barre_basse") { out += line([p.x - 0.4, p.y], [p.x + 0.4, p.y], 0.02, c) + line([p.x - 0.36, 0], [p.x - 0.36, p.y], 0.016, c) + line([p.x + 0.36, 0], [p.x + 0.36, p.y], 0.016, c); }
        else if (t === "banc") { var w = p.w || 0.55; out += rect(p.x, p.y - 0.035, w, 0.035, c, true) + line([p.x + 0.05, 0], [p.x + 0.05, p.y - 0.035], 0.02, c) + line([p.x + w - 0.05, 0], [p.x + w - 0.05, p.y - 0.035], 0.02, c); }
        else if (t === "box") { out += rect(p.x, 0, p.w || 0.3, p.h || 0.3, c, false); }
        else if (t === "mur") { out += line([p.x, 0], [p.x, 1.25], 0.02, c); }
        else if (t === "poteau") { out += line([p.x, 0], [p.x, 1.3], 0.03, c); }
        else if (t === "poulie") {
          out += circle([p.x, p.y], 0.03, c, false) + line([p.x, 0], [p.x, Math.max(p.y, 1.1)], 0.02, c, ' opacity="0.45"');
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
        else if (t === "sol_surelevé" || t === "marche") { out += rect(p.x, 0, p.w || 0.4, p.h || 0.2, c, true); }
      } else if (p.between) {
        var a = J[p.between[0]], b = J[p.between[1]];
        if (t === "baton") { var dd = norm(sub(b, a)); out += line(sub(a, mul(dd, 0.18)), add(b, mul(dd, 0.18)), 0.014, c); }
        else if (t === "corde_a_sauter") {
          // boucle dans le plan sagittal passant par les mains : sous les pieds pendant l'envol, au-dessus de la tête à l'appui
          var hx = (a[0] + b[0]) / 2, hy = (a[1] + b[1]) / 2;
          var footY = Math.min(J.pied_g[1], J.pied_d[1]);
          var other = footY > 0.03 ? footY - 0.04 : J.tete[1] + HEAD_R + 0.06;
          var cy = (hy + other) / 2, ry = Math.abs(hy - other) / 2;
          out += '<ellipse cx="' + f(hx) + '" cy="' + f(-cy) + '" rx="0.30" ry="' + f(ry) + '" fill="none" stroke="' + c + '" stroke-width="0.008"/>';
        } else if (t === "elastique") out += line(a, b, 0.012, c, ' stroke-dasharray="0.03 0.02"');
        else out += line(a, b, 0.018, c);
      } else if (p.attach) {
        var q = attachPoint(J, p.attach), o = p.offset || [0, 0];
        q = [q[0] + o[0], q[1] + o[1]];
        if (t === "barre_chargee") { out += circle(q, PLATE_R, c, true, ' fill-opacity="0.22"') + circle(q, PLATE_R, c, false) + circle(q, 0.016, c, true); }
        else if (t === "barre_vue_face") { out += line([q[0] - 0.55, q[1]], [q[0] + 0.55, q[1]], 0.016, c) + rect(q[0] - 0.62, q[1] - PLATE_R, 0.05, 2 * PLATE_R, c, true) + rect(q[0] + 0.57, q[1] - PLATE_R, 0.05, 2 * PLATE_R, c, true); }
        else if (t === "halteres") { out += line([q[0] - 0.05, q[1]], [q[0] + 0.05, q[1]], 0.012, c) + rect(q[0] - 0.06, q[1] - 0.03, 0.025, 0.06, c, true) + rect(q[0] + 0.035, q[1] - 0.03, 0.025, 0.06, c, true); }
        else if (t === "kettlebell") { out += circle([q[0], q[1] - 0.075], 0.05, c, true) + '<path d="M' + f(q[0] - 0.03) + " " + f(-(q[1] - 0.04)) + " Q " + f(q[0]) + " " + f(-(q[1] + 0.02)) + " " + f(q[0] + 0.03) + " " + f(-(q[1] - 0.04)) + '" fill="none" stroke="' + c + '" stroke-width="0.012"/>'; }
        else if (t === "lest") { out += line(J.bassin, [J.bassin[0], J.bassin[1] - 0.14], 0.006, c) + circle([J.bassin[0], J.bassin[1] - 0.19], 0.05, c, true); }
        else if (t === "medecine_ball" || t === "sac_leste") { out += circle(q, 0.07, c, t === "medecine_ball"); }
        else if (t === "roue") { out += circle([q[0], q[1] - 0.02], 0.06, c, false); }
        else if (t === "rouleau") { out += circle([q[0], 0.05], 0.05, c, false); }
        else if (t === "disque") { out += circle(q, 0.08, c, false); }
        else if (t === "gilet") { out += line(mid(J, "bassin", "cou"), J.cou, 0.1, c, ' opacity="0.35"'); }
        else if (t === "elastique_assistance") { out += line(J.prise_d, J.pied_d, 0.012, c, ' stroke-dasharray="0.03 0.02"'); }
      }
    });
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
    var x0 = Math.min.apply(null, xs) - 0.22, x1 = Math.max.apply(null, xs) + 0.22;
    var y0 = -0.06, y1 = Math.max.apply(null, ys) + 0.16;
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
      ground + drawProps(pose, J, C, "arriere") + drawBody(pose, J, C, opts.muscles) + drawProps(pose, J, C, "avant") + "</svg>";
  }

  /* Lecteur animé. opts : {accent, mode, muscles:{primaires,secondaires}, label, reduceMotion} */
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

  /* Construit l'objet « pose » attendu par le moteur à partir de poses.json v2 :
     gabarit = poses.gabarits[nom] (clés françaises), entree = poses.exercices[id] (accessoires de charge, muscles). */
  function fromPack(gabarit, entree) {
    var kfs = gabarit.images_cles.map(function (k) {
      return { label: k.label, angles: k.angles, pelvis: k.bassin, anchor: k.anchor, hold: k.hold, dur: k.dur, joints: k.joints };
    });
    var retirer = (entree && entree.retirer) || [];
    var base = (gabarit.accessoires || []).filter(function (p) { return retirer.indexOf(p.type) < 0; });
    return { view: gabarit.vue, loop: gabarit.boucle, keyframes: kfs,
      props: base.concat((entree && entree.accessoires) || []),
      muscles: (entree && entree.muscles) || {}, statut: entree ? entree.statut : "disponible" };
  }

  var api = { version: "2.0.0", fromPack: fromPack, L: L, HEAD_R: HEAD_R, WIDTH: WIDTH, MUSCLE_ZONE: MUSCLE_ZONE, fk: fk, poseOf: poseOf,
    interp: interp, ease: ease, timeline: timeline, duration: duration, jointsAt: jointsAt, svgFor: svgFor,
    staticStrip: staticStrip, bbox: bbox, roles: roles, ACCENTS: ACCENTS, Player: Player, bodyShapes: bodyShapes };
  root.KTPose = api;
  if (typeof module !== "undefined" && module.exports) module.exports = api;
})(typeof window !== "undefined" ? window : globalThis);
