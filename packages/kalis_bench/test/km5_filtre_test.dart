// Définition KM5 de `volume_trop_vite` pour une saison servie par Koach
// (C17.40.3) : port de `test_filtre_du_validateur_volume_ecrit`
// (`reference/tests/test_km5_rampe.py`).
import 'package:kalis_bench/src/km/campagne.dart' show kmFiltrerVolumeEcrit;
import 'package:test/test.dart';

Map<String, Object?> _v(int w, double val, double lim) => <String, Object?>{
  'code': 'volume_trop_vite',
  'week': w,
  'value': val,
  'limit': lim,
};

void main() {
  test('gardé seulement au-dessus de max(limite, écrit)', () {
    final servi = [
      <int, double>{0: 10.0, 4: 12.0},
      <int, double>{0: 14.0, 4: 12.0, 7: 9.0},
    ];
    final ecrit = [
      <int, double>{0: 10.0, 4: 12.0},
      <int, double>{0: 12.0, 4: 13.0, 7: 9.0},
    ];
    final out = kmFiltrerVolumeEcrit(
      [
        _v(1, 14.0, 10.0),
        _v(1, 12.0, 10.0),
        _v(1, 9.0, 8.0),
        _v(5, 3.0, 2.0),
        _v(1, 7.0, 6.0),
        <String, Object?>{
          'code': 'charge_trop_vite',
          'week': 1,
          'value': 0.2,
          'limit': 0.05,
        },
      ],
      servi,
      ecrit,
    );
    expect(
      [
        for (final c in out)
          [
            c['code'],
            c['value'],
            c.containsKey('ecrit') ? c['ecrit'] : 'absent',
          ],
      ],
      [
        ['volume_trop_vite', 14.0, 12.0],
        ['volume_trop_vite', 3.0, null],
        ['volume_trop_vite', 7.0, null],
        ['charge_trop_vite', 0.2, 'absent'],
      ],
    );
    final deux = kmFiltrerVolumeEcrit(
      [_v(0, 12.0, 10.0)],
      [
        <int, double>{0: 12.0, 4: 12.0},
      ],
      [
        <int, double>{0: 6.0, 4: 12.0},
      ],
    );
    expect([for (final c in deux) c['ecrit']], [6.0]);
  });
}
