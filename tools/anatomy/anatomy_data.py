"""M2 : données de correspondance du mannequin 3D (sans dépendance Blender).

- FR : noms français des muscles du modèle (repris de la page de référence
  validée par le propriétaire, complétés pour les muscles du cou et les
  volumes des mains et des pieds).
- REF_GROUP : groupe du modèle → groupe de l'application (page de référence).
- PACK_OF_KEY : muscle du modèle → muscles du pack (`assets/content`, clé
  `muscles`).
- GROUP_OF_MODEL : groupe de l'application retenu pour chaque muscle du
  modèle : celui du muscle du pack correspondant (`lib/atlas_data.dart`,
  cohérent avec la liste en texte et STATS), sinon celui de la page de
  référence.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

APP_GROUPS = ['pectoraux', 'épaules', 'biceps', 'triceps', 'avant-bras',
              'gainage', 'dos', 'quadriceps', 'ischios', 'fessiers', 'mollets']

SIDE_FR = {'left': 'gauche', 'right': 'droit'}

FR = {
    'deltoid_anterior': 'Deltoïde antérieur', 'deltoid_lateral': 'Deltoïde moyen',
    'deltoid_posterior': 'Deltoïde postérieur', 'supraspinatus': 'Supra-épineux',
    'infraspinatus': 'Infra-épineux', 'subscapularis': 'Subscapulaire',
    'teres_minor': 'Petit rond', 'teres_major': 'Grand rond',
    'rectus_femoris': 'Droit fémoral', 'vastus_lateralis': 'Vaste latéral',
    'vastus_medialis': 'Vaste médial', 'vastus_intermedius': 'Vaste intermédiaire',
    'biceps_femoris_long': 'Biceps fémoral (chef long)',
    'biceps_femoris_short': 'Biceps fémoral (chef court)',
    'semitendinosus': 'Semi-tendineux', 'semimembranosus': 'Semi-membraneux',
    'sartorius': 'Sartorius', 'adductor_magnus': 'Grand adducteur',
    'adductor_longus': 'Long adducteur', 'adductor_brevis': 'Court adducteur',
    'gracilis': 'Gracile', 'pectineus': 'Pectiné',
    'pectoralis_major_clavicular': 'Grand pectoral (chef claviculaire)',
    'pectoralis_major_sternocostal': 'Grand pectoral (chef sterno-costal)',
    'pectoralis_major_abdominal': 'Grand pectoral (chef abdominal)',
    'pectoralis_minor': 'Petit pectoral', 'serratus_anterior': 'Dentelé antérieur',
    'trapezius_upper': 'Trapèze supérieur', 'trapezius_middle': 'Trapèze moyen',
    'trapezius_lower': 'Trapèze inférieur', 'latissimus_dorsi': 'Grand dorsal',
    'rhomboid_major': 'Grand rhomboïde', 'rhomboid_minor': 'Petit rhomboïde',
    'levator_scapulae': 'Élévateur de la scapula',
    'serratus_posterior_inferior': 'Dentelé postérieur inférieur',
    'serratus_posterior_superior': 'Dentelé postérieur supérieur',
    'iliocostalis_lumborum': 'Ilio-costal lombal',
    'iliocostalis_thoracis': 'Ilio-costal thoracique',
    'longissimus_thoracis': 'Longissimus thoracique',
    'spinalis_thoracis': 'Épineux thoracique', 'multifidus_lumborum': 'Multifide',
    'rectus_abdominis': "Droit de l'abdomen", 'transversus_abdominis': 'Transverse',
    'external_oblique': 'Oblique externe', 'internal_oblique': 'Oblique interne',
    'quadratus_lumborum': 'Carré des lombes',
    'sternocleidomastoid': 'Sterno-cléido-mastoïdien',
    'scalenus_medius': 'Scalène moyen', 'scalenus_anterior': 'Scalène antérieur',
    'scalenus_posterior': 'Scalène postérieur',
    'splenius_capitis': 'Splénius de la tête', 'splenius_colli': 'Splénius du cou',
    'biceps_brachii_long': 'Biceps brachial (chef long)',
    'biceps_brachii_short': 'Biceps brachial (chef court)',
    'brachialis': 'Brachial', 'coracobrachialis': 'Coraco-brachial',
    'triceps_long': 'Triceps (chef long)', 'triceps_lateral': 'Triceps (chef latéral)',
    'triceps_medial': 'Triceps (chef médial)', 'brachioradialis_muscle': 'Brachio-radial',
    'flexor_carpi_radialis': 'Fléchisseur radial du carpe',
    'palmaris_longus_muscle': 'Long palmaire',
    'humeral_head_of_flexor_carpi_ulnaris': 'Fléchisseur ulnaire du carpe (chef huméral)',
    'ulnar_head_of_flexor_carpi_ulnaris': 'Fléchisseur ulnaire du carpe (chef ulnaire)',
    'humero_ulnar_head_of_flexor_digitorum_superficialis':
        'Fléchisseur superficiel des doigts (chef huméro-ulnaire)',
    'radial_head_of_flexor_digitorum_superficialis':
        'Fléchisseur superficiel des doigts (chef radial)',
    'flexor_digitorum_profundus': 'Fléchisseur profond des doigts',
    'flexor_pollicis_longus': 'Long fléchisseur du pouce',
    'pronator_quadratus': 'Carré pronateur',
    'superficial_head_of_pronator_teres': 'Rond pronateur (chef superficiel)',
    'deep_head_of_pronator_teres': 'Rond pronateur (chef profond)',
    'supinator': 'Supinateur', 'extensor_digitorum': 'Extenseur des doigts',
    'ulnar_head_of_extensor_carpi_ulnaris': 'Extenseur ulnaire du carpe (chef ulnaire)',
    'humeral_head_of_extensor_carpi_ulnaris': 'Extenseur ulnaire du carpe (chef huméral)',
    'extensor_carpi_radialis_longus': 'Long extenseur radial du carpe',
    'extensor_carpi_radialis_brevis': 'Court extenseur radial du carpe',
    'anconeus_muscle': 'Anconé', 'extensor_digiti_minimi': 'Extenseur du petit doigt',
    'abductor_pollicis_longus': 'Long abducteur du pouce',
    'extensor_indicis': "Extenseur de l'index",
    'extensor_pollicis_brevis': 'Court extenseur du pouce',
    'extensor_pollicis_longus': 'Long extenseur du pouce',
    'gluteus_maximus': 'Grand fessier', 'gluteus_medius': 'Moyen fessier',
    'gluteus_minimus': 'Petit fessier', 'iliacus': 'Iliaque', 'psoas_major': 'Grand psoas',
    'tensor_fasciae_latae': 'Tenseur du fascia lata', 'piriformis': 'Piriforme',
    'quadratus_femoris': 'Carré fémoral', 'obturator_internus': 'Obturateur interne',
    'obturator_externus': 'Obturateur externe', 'gemellus_inferior': 'Jumeau inférieur',
    'gemellus_superior': 'Jumeau supérieur',
    'gastrocnemius_lateral': 'Gastrocnémien latéral',
    'gastrocnemius_medial': 'Gastrocnémien médial', 'soleus': 'Soléaire',
    'plantaris': 'Plantaire', 'tibialis_anterior': 'Tibial antérieur',
    'tibialis_posterior': 'Tibial postérieur', 'fibularis_longus': 'Long fibulaire',
    'fibularis_brevis': 'Court fibulaire', 'fibularis_tertius': 'Troisième fibulaire',
    'extensor_digitorum_longus': 'Long extenseur des orteils',
    'extensor_hallucis_longus': "Long extenseur de l'hallux",
    'flexor_digitorum_longus': 'Long fléchisseur des orteils',
    'flexor_hallucis_longus': "Long fléchisseur de l'hallux", 'popliteus': 'Poplité',
    # M4b : nappe du cou remise (absente de la carte source, tirée du
    # support « head_hands_feet »).
    'platysma': 'Platysma',
    # Volumes sombres simplifiés (M2) : sélectionnables comme muscles
    # intrinsèques de la main et du pied (pack).
    'hand_intrinsic': 'Muscles de la main',
    'foot_intrinsic': 'Muscles du pied',
}

# Groupe du modèle → groupe de l'application (page de référence validée ;
# « Neck » absent de la page : groupe du sterno-cléido-mastoïdien du pack).
REF_GROUP = {
    'Chest': 'pectoraux', 'Deltoids': 'épaules', 'Rotator cuff': 'épaules',
    'Biceps': 'biceps', 'Upper arms': 'biceps', 'Triceps': 'triceps',
    'Forearms': 'avant-bras', 'Abdominals': 'gainage', 'Obliques': 'gainage',
    'Serratus': 'gainage', 'Lower back': 'gainage', 'Hip flexors': 'gainage',
    'Lats': 'dos', 'Trapezius': 'dos', 'Upper back': 'dos', 'Teres major': 'dos',
    'Spinal extensors': 'dos', 'Quadriceps': 'quadriceps', 'Sartorius': 'quadriceps',
    'Adductors': 'quadriceps', 'Hamstrings': 'ischios', 'Glutes': 'fessiers',
    'Hip rotators': 'fessiers', 'Calves': 'mollets', 'Lower legs': 'mollets',
    'Neck': 'dos', 'Hand': 'avant-bras', 'Foot': 'mollets',
}

# Muscle du modèle → muscles du pack (vide : pas d'équivalent dans le pack).
PACK_OF_KEY = {
    'deltoid_anterior': ['deltoide_anterieur'], 'deltoid_lateral': ['deltoide_moyen'],
    'deltoid_posterior': ['deltoide_posterieur'], 'supraspinatus': ['supra_epineux'],
    'infraspinatus': ['infra_epineux'], 'subscapularis': ['sous_scapulaire'],
    'teres_minor': ['petit_rond'], 'teres_major': ['grand_rond'],
    'rectus_femoris': ['droit_femoral'], 'vastus_lateralis': ['vaste_lateral'],
    'vastus_medialis': ['vaste_medial'], 'vastus_intermedius': ['vaste_intermediaire'],
    'biceps_femoris_long': ['biceps_femoral'],
    'biceps_femoris_short': ['biceps_femoral_chef_court'],
    'semitendinosus': ['semi_tendineux'], 'semimembranosus': ['semi_membraneux'],
    'sartorius': ['sartorius'], 'adductor_magnus': ['grand_adducteur'],
    'adductor_longus': ['long_adducteur'], 'adductor_brevis': ['court_adducteur'],
    'gracilis': ['gracile'], 'pectineus': ['pectine'],
    'pectoralis_major_clavicular': ['grand_pectoral_claviculaire'],
    'pectoralis_major_sternocostal': ['grand_pectoral_sterno_costal'],
    'pectoralis_major_abdominal': ['grand_pectoral_abdominal'],
    'pectoralis_minor': ['petit_pectoral'], 'serratus_anterior': ['dentele_anterieur'],
    'trapezius_upper': ['trapeze_superieur'], 'trapezius_middle': ['trapeze_moyen'],
    'trapezius_lower': ['trapeze_inferieur'], 'latissimus_dorsi': ['grand_dorsal'],
    'rhomboid_major': ['rhomboides'], 'rhomboid_minor': ['rhomboides'],
    'levator_scapulae': ['elevateur_scapula'],
    'serratus_posterior_inferior': [], 'serratus_posterior_superior': [],
    'iliocostalis_lumborum': ['erecteurs_lombaires'],
    'iliocostalis_thoracis': ['erecteurs_thoraciques'],
    'longissimus_thoracis': ['erecteurs_thoraciques', 'erecteurs_lombaires'],
    'spinalis_thoracis': ['erecteurs_thoraciques'],
    'multifidus_lumborum': ['multifides'],
    'rectus_abdominis': ['droit_abdomen'], 'transversus_abdominis': ['transverse_abdomen'],
    'external_oblique': ['oblique_externe'], 'internal_oblique': ['oblique_interne'],
    'quadratus_lumborum': ['carre_des_lombes'],
    'sternocleidomastoid': ['sterno_cleido_mastoidien'],
    'scalenus_medius': [], 'scalenus_anterior': [], 'scalenus_posterior': [],
    'splenius_capitis': ['extenseurs_cervicaux'], 'splenius_colli': ['extenseurs_cervicaux'],
    'biceps_brachii_long': ['biceps_chef_long'], 'biceps_brachii_short': ['biceps_chef_court'],
    'brachialis': ['brachial'], 'coracobrachialis': ['coraco_brachial'],
    'triceps_long': ['triceps_chef_long'], 'triceps_lateral': ['triceps_chef_lateral'],
    'triceps_medial': ['triceps_chef_medial'], 'brachioradialis_muscle': ['brachio_radial'],
    'flexor_carpi_radialis': ['flechisseurs_du_poignet'],
    'palmaris_longus_muscle': ['flechisseurs_du_poignet'],
    'humeral_head_of_flexor_carpi_ulnaris': ['flechisseurs_du_poignet'],
    'ulnar_head_of_flexor_carpi_ulnaris': ['flechisseurs_du_poignet'],
    'humero_ulnar_head_of_flexor_digitorum_superficialis':
        ['flechisseurs_superficiels_des_doigts'],
    'radial_head_of_flexor_digitorum_superficialis':
        ['flechisseurs_superficiels_des_doigts'],
    'flexor_digitorum_profundus': ['flechisseurs_profonds_des_doigts'],
    'flexor_pollicis_longus': ['flechisseurs_profonds_des_doigts'],
    'pronator_quadratus': ['carre_pronateur'],
    'superficial_head_of_pronator_teres': ['rond_pronateur'],
    'deep_head_of_pronator_teres': ['rond_pronateur'],
    'supinator': ['supinateur'], 'extensor_digitorum': ['extenseurs_des_doigts'],
    'ulnar_head_of_extensor_carpi_ulnaris': ['extenseurs_du_poignet'],
    'humeral_head_of_extensor_carpi_ulnaris': ['extenseurs_du_poignet'],
    'extensor_carpi_radialis_longus': ['extenseurs_du_poignet'],
    'extensor_carpi_radialis_brevis': ['extenseurs_du_poignet'],
    'anconeus_muscle': ['ancone'], 'extensor_digiti_minimi': ['extenseurs_des_doigts'],
    'abductor_pollicis_longus': ['extenseurs_des_doigts'],
    'extensor_indicis': ['extenseurs_des_doigts'],
    'extensor_pollicis_brevis': ['extenseurs_des_doigts'],
    'extensor_pollicis_longus': ['extenseurs_des_doigts'],
    'gluteus_maximus': ['grand_fessier'], 'gluteus_medius': ['moyen_fessier'],
    'gluteus_minimus': ['petit_fessier'], 'iliacus': ['iliaque'],
    'psoas_major': ['grand_psoas'], 'tensor_fasciae_latae': ['tenseur_fascia_lata'],
    'piriformis': ['rotateurs_lateraux_hanche'],
    'quadratus_femoris': ['rotateurs_lateraux_hanche'],
    'obturator_internus': ['rotateurs_lateraux_hanche'],
    'obturator_externus': ['rotateurs_lateraux_hanche'],
    'gemellus_inferior': ['rotateurs_lateraux_hanche'],
    'gemellus_superior': ['rotateurs_lateraux_hanche'],
    'gastrocnemius_lateral': ['gastrocnemien_lateral'],
    'gastrocnemius_medial': ['gastrocnemien_medial'], 'soleus': ['soleaire'],
    'plantaris': [], 'tibialis_anterior': ['tibial_anterieur'],
    'tibialis_posterior': ['tibial_posterieur'], 'fibularis_longus': ['fibulaires'],
    'fibularis_brevis': ['fibulaires'], 'fibularis_tertius': ['fibulaires'],
    'extensor_digitorum_longus': ['long_extenseur_des_orteils'],
    'extensor_hallucis_longus': ['long_extenseur_des_orteils'],
    'flexor_digitorum_longus': ['flechisseurs_profonds_des_orteils'],
    'flexor_hallucis_longus': ['flechisseurs_profonds_des_orteils'],
    'popliteus': ['poplite'],
    'platysma': [],
    'hand_intrinsic': ['muscles_intrinseques_main'],
    'foot_intrinsic': ['muscles_intrinseques_pied'],
}

# Volumes sombres du modèle d'exécution : id du nœud → (clé, côté) ; la tête
# n'est pas un muscle (aucune mise en évidence).
VOLUME_REGIONS = {
    'head': (None, None),
    'hand_left': ('hand_intrinsic', 'left'), 'hand_right': ('hand_intrinsic', 'right'),
    'foot_left': ('foot_intrinsic', 'left'), 'foot_right': ('foot_intrinsic', 'right'),
}


def model_groups():
    """Groupe du modèle (source) pour chaque clé."""
    import json
    data = json.loads((Path(__file__).resolve().parent / 'source/full-body-map.json').read_text())
    groups = {m['key']: m['group'] for m in data['muscles']}
    groups['hand_intrinsic'] = 'Hand'
    groups['foot_intrinsic'] = 'Foot'
    groups['platysma'] = 'Neck'
    return groups


def pack_muscles():
    """Muscles du pack (lib/atlas_data.dart, généré depuis le pack) :
    {id: (groupe, profondeur)}."""
    text = (ROOT / 'lib/atlas_data.dart').read_text(encoding='utf-8')
    text = text[text.index('atlasMuscles'):]
    out = {}
    pattern = re.compile(
        r"'(\w+)':\s*AtlasMuscle\(\s*'((?:[^'\\]|\\.)*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)'",
        re.S)
    for m in pattern.finditer(text):
        out[m.group(1)] = (m.group(4), m.group(5))
    return out


def group_of_model():
    """Groupe retenu : celui du pack (premier muscle correspondant) s'il
    existe, sinon celui de la page de référence."""
    pack = pack_muscles()
    out, conflicts = {}, {}
    for key, group in model_groups().items():
        ref = REF_GROUP[group]
        packs = [pack[p][0] for p in PACK_OF_KEY[key] if p in pack]
        chosen = packs[0] if packs else ref
        if chosen != ref:
            conflicts[key] = {'reference': ref, 'pack': chosen}
        out[key] = chosen
    return out, conflicts


GROUP_OF_MODEL, GROUP_CONFLICTS = group_of_model()
