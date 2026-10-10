F='/root/.claude/projects/-home-claude-streetlift-apk/560475ee-797b-5663-a628-411bcd12457d/tool-results/artifact-37d408fa-1791621907-f73e.html'
s=open(F,encoding='utf-8').read()
i=s.index('<title>Suivi Kalis Track GP</title>')
j=s.rindex('</body>') if '</body>' in s else len(s)
s=s[i:j]
sec=open('/home/claude/km1-outils/page/section_c1.html',encoding='utf-8').read()
a='  <section class="lot" id="km1">'
assert s.count(a)==1
s=s.replace(a,sec+a)
old='<span class="pill wait">À valider</span>\n      <span class="pill wait">6 critères sur 11</span>'
assert old in s
s=s.replace(old,'<span class="pill todo">Remplacé par la correction 1</span>\n      <span class="pill todo">6 critères sur 11</span>')
k=s.index('          <tr class="current"><td>KM1</td>'); e=s.index('\n',k)
ligne=s[k:e]
nouvelle=ligne.replace('<tr class="current">','<tr>').replace('<span class="pill wait">À valider</span>','<span class="pill todo">Remplacé</span>')
c1="          <tr class=\"current\"><td>KM1 c1</td><td>Méthode Koach : correction 1, Koach 1.0.1 (7 critères du cahier sur 11, 0 violation de sécurité ; mauvais jour 0,95 % ; jour J 94,1 % ; erreur d'e1RM 4,0 % pour 3 % visés ; à trancher)</td><td>auto</td><td class=\"num\">référence 1.0.1</td><td><span class=\"pill wait\">À trancher</span></td></tr>"
s=s[:k]+nouvelle+'\n'+c1+s[e:]
open('/home/claude/km1-outils/page/suivi.html','w',encoding='utf-8').write(s)
print(len(s), s[:40], repr(s[-120:]))
