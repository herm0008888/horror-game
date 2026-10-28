from pathlib import Path
import json,re,collections
root=Path(__file__).resolve().parents[2];groups=collections.defaultdict(dict)
for source,dest in json.loads((root/'tools/house/compact_mesh_map.json').read_text()).items():
 scene,subid=source.split('::');groups[scene][subid]=dest
before=after=0
for scene,resources in groups.items():
 p=root/scene.removeprefix('res://');s=p.read_text();before+=p.stat().st_size;extra=[]
 for subid,dest in resources.items():
  pattern=r'(?ms)^\[sub_resource type="ArrayMesh" id="'+re.escape(subid)+r'"\]\n.*?(?=^\[|\Z)'
  s,n=re.subn(pattern,'',s)
  if n!=1:raise RuntimeError('Expected exactly one block '+scene+' '+subid+' '+str(n))
  rid='optimized_'+dest.rsplit('/',1)[1][5:29]
  s=s.replace('SubResource("'+subid+'")','ExtResource("'+rid+'")')
  extra.append('[ext_resource type="ArrayMesh" path="'+dest+'" id="'+rid+'"]')
 pos=s.find('\n\n');s=s[:pos+2]+'\n'.join(extra)+'\n'+s[pos+2:];p.write_text(s);after+=p.stat().st_size
refs=set()
for p in (root/'scenes').rglob('*.tscn'):refs.update(re.findall(r'res://assets/house_optimized/(mesh_[a-f0-9]+\.res)',p.read_text()))
folder=(root/'assets/house_optimized').resolve()
for p in folder.glob('mesh_*.res'):
 if p.name not in refs:
  assert p.resolve().is_relative_to(folder);p.unlink()
binary=sum((folder/n).stat().st_size for n in refs)
report={'source_scene_bytes':before,'new_scene_bytes':after,'binary_mesh_bytes':binary,'total_reduction_percent':100*(1-(after+binary)/before),'unique_meshes':len(refs)}
(root/'tools/house/compact_mesh_report.json').write_text(json.dumps(report,indent=2));print(report)
