#!/usr/bin/env python3
"""Generate I3_MODE_FSM_ALL.dot from the i3 config (config/i3/config + config.d/*.config).

Usage: python3 tools/gen_mode_fsm.py [> I3_MODE_FSM_ALL.dot]
       python3 tools/gen_mode_fsm.py --summary   # counts + problems, no dot output

Per mode: label (text before ':' in `set $mode_x ...`), source line, number of actions
(bindings that run something) and how many of them keep the mode ("repeat").
Edges: mode entries (blue, labelled with keys), Enter/Return to a parent (gray dashed),
targets that are not defined (red). Returns to default are summarised in the legend.
"""
import os, re, sys
from collections import OrderedDict, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
I3 = os.path.normpath(os.path.join(HERE, '..', '..', '..'))          # config/i3
FILES = [os.path.join(I3, 'config')] + sorted(
    os.path.join(I3, 'config.d', f) for f in os.listdir(os.path.join(I3, 'config.d')) if f.endswith('.config'))
CLUSTER_COLOR = {'i3_mode.config': '#dbeafe', 'i3_custom.config': '#fce7f3', 'i3_gap.config': '#fef3c7',
                 'i3_bar.config': '#dcfce7', 'i3_workspace.config': '#e0e7ff', 'i3_bindkey.config': '#ede9fe'}
NAV_KEYS = {'Escape', 'Return', 'Ctrl+bracketleft', 'KP_Enter'}
# Modes kept out of this repository on purpose (defined privately): no node, no edge, not
# reported as undefined.
HIDDEN_MODES = {'mode_clink'}

def split_cmds(s):
    out, cur, q = [], '', None
    for ch in s:
        if q:
            cur += ch
            if ch == q: q = None
        elif ch in '"\'':
            q = ch; cur += ch
        elif ch in ';,':
            out.append(cur.strip()); cur = ''
        else:
            cur += ch
    out.append(cur.strip())
    return [c for c in out if c]

labels, set_line = {}, {}
modes = OrderedDict()            # name -> dict(file, line, bindings=[(key, cmds)])
default_bindings = []            # (key, cmds, file, line)
for path in FILES:
    fname = os.path.basename(path)
    cur = None
    for n, raw in enumerate(open(path, encoding='utf-8', errors='replace'), 1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        m = re.match(r'set\s+\$(mode_\w+)\s+(.*)', line)
        if m:
            # text before the first ':', without a trailing key hint such as ' [1]'
            labels[m.group(1)] = re.sub(r'\s*\[[^\]]{1,3}\]\S*$', '', m.group(2).split(':')[0].strip())
            set_line[m.group(1)] = (fname, n)
            continue
        m = re.match(r'mode\s+(?:--pango_markup\s+)?"\$(mode_\w+)"\s*\{', line)
        if m:
            cur = m.group(1)
            modes[cur] = {'file': fname, 'line': n, 'bindings': []}
            continue
        if cur and line == '}':
            cur = None
            continue
        m = re.match(r'bindsym\s+((?:--\S+\s+)*)(\S+)\s+(.*)', line)
        if m:
            key, cmds = m.group(2), split_cmds(m.group(3))
            if cur:
                modes[cur]['bindings'].append((key, cmds))
            else:
                default_bindings.append((key, cmds, fname, n))

def target(cmds):
    for c in cmds:
        m = re.match(r'mode\s+"?\$?(mode_\w+|default)"?', c)
        if m:
            return m.group(1)
    return None

def is_action(cmds):
    return any(not re.match(r'mode\s', c) for c in cmds)

entries = defaultdict(list)      # (src, dst) -> keys
enter_parent = {}                # src -> dst
undefined = set()
stats = {}
for name, info in modes.items():
    actions = repeat = 0
    for key, cmds in info['bindings']:
        t = target(cmds)
        if is_action(cmds):
            actions += 1
            if t is None:
                repeat += 1
        if t in HIDDEN_MODES:
            continue
        if t and t != 'default':
            if t not in modes:
                undefined.add(t)
            if key in ('Return', 'KP_Enter') and not is_action(cmds):
                enter_parent[name] = t
            else:
                entries[(name, t)].append(key)
    stats[name] = (actions, repeat)
for key, cmds, fname, n in default_bindings:
    t = target(cmds)
    if t in HIDDEN_MODES:
        continue
    if t and t != 'default':
        if t not in modes:
            undefined.add(t)
        entries[('default', t)].append(key)

reachable = {'default'}
changed = True
while changed:
    changed = False
    for (s, d) in entries:
        if s in reachable and d not in reachable:
            reachable.add(d); changed = True
unreachable = [m for m in modes if m not in reachable]

if '--summary' in sys.argv:
    print(f'modes defined: {len(modes)}')
    print(f'entry edges: {len(entries)}; enter-to-parent: {len(enter_parent)}')
    print(f'entered from default: {len([1 for (s, d) in entries if s == "default"])}')
    print('undefined targets:', ', '.join(sorted(undefined)) or 'none')
    print('unreachable modes:', ', '.join(unreachable) or 'none')
    missing_label = [m for m in modes if m not in labels]
    print('modes without label:', ', '.join(missing_label) or 'none')
    sys.exit(0)

def q(s):
    return s.replace('\\', '\\\\').replace('"', '\\"')

def keylabel(keys):
    keys = list(OrderedDict.fromkeys(keys))
    text = ' / '.join(keys[:4]) + (' …' if len(keys) > 4 else '')
    return q(text)

out = []
w = out.append
w('digraph I3ModeFSM {')
w(f'graph [label="i3 mode state machine — all {len(modes)} defined modes (generated by tools/gen_mode_fsm.py)",labelloc=t,fontsize=30,fontname="DejaVu Sans",rankdir=LR,ranksep=0.8,nodesep=0.25,splines=polyline,pad=0.25];')
w('node [shape=box,style="rounded,filled",fontname="DejaVu Sans",fontsize=14,margin="0.12,0.08",color="#64748b"];')
w('edge [fontname="DejaVu Sans",fontsize=12,color="#2563eb"];')
w('default [label="default\\nnormal i3 bindings",shape=oval,fillcolor="#bfdbfe",penwidth=2];')
w('rofi [label="Rofi dialog\\nEsc: close/back\\nOmnisearch Alt+B: Search",shape=note,fillcolor="#e9d5ff"];')
by_file = OrderedDict()
for name, info in modes.items():
    by_file.setdefault(info['file'], []).append(name)
for fname, names in by_file.items():
    color = CLUSTER_COLOR.get(fname, '#f1f5f9')
    w(f'subgraph "cluster_{fname.replace(".", "_")}" {{')
    w(f'label="{fname}"; style=rounded; color="{color}";')
    for name in names:
        a, r = stats[name]
        info = modes[name]
        lab = q(labels.get(name, name))
        w(f'"{name}" [label="{lab}\\n{a} action{"s" if a != 1 else ""} · {r} repeat",fillcolor="{color}",URL="../../config.d/{info["file"]}#L{info["line"]}"];'
          if info['file'] != 'config' else
          f'"{name}" [label="{lab}\\n{a} actions · {r} repeat",fillcolor="{color}"];')
    w('}')
for name in sorted(undefined):
    w(f'"{name}" [label="UNDEFINED: {name}",fillcolor="#fee2e2",color="#dc2626"];')
for (s, d), keys in entries.items():
    color = '#dc2626' if d in undefined else ('#1d4ed8' if s == 'default' else '#2563eb')
    src = 'default' if s == 'default' else f'"{s}"'
    w(f'{src} -> "{d}" [label="{keylabel(keys)}",color="{color}"];')
for s, d in enter_parent.items():
    w(f'"{s}" -> "{d}" [label="Enter",style=dashed,color="#94a3b8",constraint=false];')
w('default -> rofi [label="Super+Backslash / app, window, mark selectors",color="#9333ea"];')
w('rofi -> default [label="close / action",color="#9333ea",constraint=false];')
w('sharing [label="Sharing outside i3 modes\\nToolkit l → LocalSend CLI (floating)\\nRanger ,s → send selection; ,r → receive here",shape=note,fillcolor="#ccfbf1"];')
if 'mode_toolkit' in modes:
    w('"mode_toolkit" -> sharing [style=dotted,color="#0f766e",label="l"];')
w('legend [label="Blue: mode entry (keys) · gray dashed: Enter to parent · red: undefined target\\nMost modes: Esc or Ctrl+[ → default; Mouse differs\\nActions that keep the mode count as repeat",shape=note,fillcolor="#f8fafc"];')
w('}')
print('\n'.join(out))
