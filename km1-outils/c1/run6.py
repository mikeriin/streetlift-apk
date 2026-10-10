# run6.py <profils|tous> <graines> : lance diag6 avec un module de patch optionnel (env PATCH)
import os,sys,runpy
sys.path.insert(0,'/home/claude/km1-outils/c1')
if os.environ.get('PATCH'): __import__(os.environ['PATCH'])
sys.argv=['diag6.py']+sys.argv[1:]
runpy.run_path('/home/claude/km1-outils/c1/diag6.py',run_name='__main__')
