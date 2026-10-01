import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/search.dart';

void main() {
  test('normalisation : accents, casse, ponctuation, tirets conservés', () {
    expect(
      normalizeText('Échelle 21-15-9 · Tractions & Pompes'),
      'echelle 21-15-9 tractions pompes',
    );
    expect(normalizeText('  MU  ×3 '), 'mu x3');
    expect(normalizeText('d’activation'), 'd activation');
  });

  test('recherche : synonymes FR / EN, plusieurs termes, préfixes', () {
    final doc = SearchDoc(
      name: '5 rounds · pull-ups & push-ups + 400 m run',
      meta: 'Rounds for time',
      body: '8 pull-ups | 12 push-ups | 400 m run',
    );
    expect(SearchQuery('traction').matches(doc.all), isTrue);
    expect(SearchQuery('pompes course').matches(doc.all), isTrue);
    expect(SearchQuery('trac').matches(doc.all), isTrue);
    expect(SearchQuery('PULL-UPS').matches(doc.all), isTrue);
    expect(SearchQuery('dips').matches(doc.all), isFalse);
    expect(SearchQuery('pompes dips').matches(doc.all), isFalse);
    expect(SearchQuery('introuvable-12345').matches(doc.all), isFalse);
    expect(SearchQuery('').isEmpty, isTrue);
    expect(SearchQuery('   ').isEmpty, isTrue);
  });

  test('pertinence : le titre pèse plus que les lignes', () {
    final a = SearchDoc(
      name: 'Death by · burpees',
      body: 'min 1-5 : 3 burpees',
    );
    final b = SearchDoc(name: 'AMRAP 12 · pompes', body: '10 burpees');
    final q = SearchQuery('burpees');
    expect(q.score(a), greaterThan(q.score(b)));
    expect(q.score(b), greaterThan(0));
  });

  test('index : un document n’est reconstruit que si sa clé change', () {
    final index = SearchIndex<String>();
    var builds = 0;
    SearchDoc build() {
      builds++;
      return SearchDoc(name: 'x');
    }

    index.doc('a', 'k1', build);
    index.doc('a', 'k1', build);
    expect(builds, 1);
    index.doc('a', 'k2', build);
    expect(builds, 2);
  });
}
