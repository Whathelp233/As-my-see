#!/usr/bin/env python3
"""Installation-height calibration demo (Python standard library only).

Uses line_laser_pitch_demo.py in the same directory to generate synthetic rays
and refit unknown walls. The height solver receives only measured ray points,
robot poses, and the measured ground-line distance; not the simulated true
height or validation-block heights. Other extrinsics are held fixed, so this
illustrates height observability rather than replacing full 6-DOF calibration.

Run: python3 line_laser_height_observability.py
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

import line_laser_pitch_observability as geometry


# The solver's 155–215 mm search interval and the simulated 181 mm height are
# teaching values for a synthetic scene, not recommended device parameters.


def solve_height(data, c):
    """Global coarse scan, then local golden-section refinement; no height prior."""
    def error(h):
        return geometry.wall_rms(data, math.asin(h / c)) ** 2
    grid = [0.155 + i * 0.001 for i in range(61)]
    best = min(grid, key=error)
    lo, hi = max(grid[0], best - 0.001), min(grid[-1], best + 0.001)
    ratio = (math.sqrt(5) - 1) / 2
    a, b = hi - ratio * (hi - lo), lo + ratio * (hi - lo)
    fa, fb = error(a), error(b)
    for _ in range(70):
        if fa < fb:
            hi, b, fb = b, a, fa
            a = hi - ratio * (hi - lo)
            fa = error(a)
        else:
            lo, a, fa = a, b, fb
            b = lo + ratio * (hi - lo)
            fb = error(b)
    return (lo + hi) / 2


HTML = r'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>安装高度标定：从 200 mm 初值求解</title><style>__CSS__
.calibration-status{min-height:80px}.plots canvas{height:280px}.validation{margin-top:20px}.solve-path{color:var(--muted);overflow-wrap:anywhere;font-variant-numeric:tabular-nums}button.primary{background:var(--fg);color:var(--bg)}
</style></head><body><main>
<h1>安装高度：从 200 mm 初值开始求解</h1>
<p>模拟真实安装高度 <strong>181 mm</strong>。先给程序一个 <strong>200 mm</strong> 初值，再让它用观测数据寻找安装高度。</p>
<div class="controls"><label for="mode">用于标定的数据</label><select id="mode"><option value="corner">地面 + 六站点墙角</option><option value="ground">只有地面</option></select><button class="primary" id="solve">从当前高度开始标定</button><button id="reset">恢复 200 mm 初值</button></div>
<label for="height">当前假定的安装高度：<strong id="height-label">200.00 mm</strong></label>
<input class="slider" id="height" type="range" min="155" max="215" step="0.01" value="200" aria-label="假定安装高度，单位毫米">
<div class="metrics" aria-live="polite"><span>配套倾角：<strong id="angle"></strong></span><span>地面残差：<strong>0 mm</strong></span><span>墙面残差：<strong id="rms"></strong></span></div>
<p class="calibration-status" id="status" aria-live="polite"></p>
<div class="plots"><div class="plot"><h2>高度改变，角度跟着改变</h2><div class="legend"><span><i class="swatch true"></i>真实安装</span><span><i class="swatch trial"></i>当前假定</span></div><canvas id="scene" role="img" aria-label="侧视比较真实安装高度与当前假定高度，两者都可以把地面点放在地上"></canvas></div><div class="plot"><h2>哪一个高度最能解释数据？</h2><div class="legend"><span><i class="swatch a"></i>各候选高度的拟合残差</span><span><i class="swatch trial"></i>当前候选</span></div><canvas id="cost" role="img" aria-label="候选安装高度和拟合残差曲线，墙角数据使正确高度附近出现最低点"></canvas></div></div>
<p class="solve-path" id="path" aria-live="polite">点击标定后显示候选高度的变化。</p>
<div class="validation"><h2>独立检查：已知高度垫块会算成多高？</h2><p>这两个垫块没有参与标定，只用来检查求出的高度尺度。假定激光照到平顶面。</p>
<table><thead><tr><th>垫块实际高度</th><th>外参计算出的高度</th><th>误差</th></tr></thead><tbody><tr><td>30 mm</td><td id="block30"></td><td id="error30"></td></tr><tr><td>50 mm</td><td id="block50"></td><td id="error50"></td></tr></tbody></table></div>
<h2>程序怎样把高度找回来？</h2>
<p>先尝试一个高度，用地面线算出配套倾角；再把六个站点看到的墙面点拼起来。墙的位置和方向都允许重新拟合，比较剩余的不一致。最后选残差最小的高度。</p>
<pre>① 尝试高度 H
② 地面线面内距离 c = 242.8 mm
   配套倾角 beta = asin(H / c)
③ 用这个高度、倾角转换各站点的激光点
④ 重新拟合同两面墙的位置和方向，计算墙面残差
⑤ 搜索使墙面残差最小的 H

只有地面：很多 H 都能满足地面残差 = 0，无法独立选出高度。
加上多站点墙角：不同 H 的墙面残差不同，可以寻找最低点。</pre>
<p class="muted">无噪声简化模型，搜索范围 155–215 mm；其他外参和机器人位姿固定，墙面对应关系已知。求解器没有使用 181 mm 真值或垫块高度作为先验。实际 corner 联合优化完整外参，还会受到测距误差、位姿误差和点分类影响。精确恢复模拟真值不代表实车达到同样精度。</p>
</main><script>
const DATA=__DATA__,POSES=__POSES__,C=__C__,TRUE_H=__TRUE_H__,LY=Math.PI/4,VALIDATION=__VALIDATION__;
const heightInput=document.getElementById('height'),mode=document.getElementById('mode'),solveButton=document.getElementById('solve');
let candidate=.200,animation=null,cache={},profile=[];
function color(name){if(!cache[name]){const probe=document.createElement('span');probe.style.color='var('+name+')';document.body.appendChild(probe);cache[name]=getComputedStyle(probe).color;probe.remove()}return cache[name]}
function wallFit(points){const n=points.length,mx=points.reduce((s,p)=>s+p[0],0)/n,my=points.reduce((s,p)=>s+p[1],0)/n;let xx=0,yy=0,xy=0;for(const [x,y] of points){xx+=(x-mx)**2/n;yy+=(y-my)**2/n;xy+=(x-mx)*(y-my)/n}const a=.5*Math.atan2(2*xy,xx-yy),nx=-Math.sin(a),ny=Math.cos(a),d=nx*mx+ny*my;return points.reduce((s,p)=>s+(nx*p[0]+ny*p[1]-d)**2,0)/n}
// This solver path deliberately never reads TRUE_H or VALIDATION.
function objective(h){const beta=Math.asin(h/C),cb=Math.cos(beta),groups={A:[],B:[]};for(const p of DATA){const pose=POSES[p.station],a=LY+pose[2]*Math.PI/180,x=p.qx*cb,y=p.qy;groups[p.wall].push([pose[0]+x*Math.cos(a)-y*Math.sin(a),pose[1]+x*Math.sin(a)+y*Math.cos(a)])}return (groups.A.length*wallFit(groups.A)+groups.B.length*wallFit(groups.B))/DATA.length}
function solve(){const trace=[{h:candidate,cost:objective(candidate)}];let best=trace[0];for(let i=0;i<=60;i++){const h=.155+i*.001,cost=objective(h);if(cost<best.cost){best={h,cost};trace.push(best)}}let lo=Math.max(.155,best.h-.001),hi=Math.min(.215,best.h+.001),ratio=(Math.sqrt(5)-1)/2,a=hi-ratio*(hi-lo),b=lo+ratio*(hi-lo),fa=objective(a),fb=objective(b);for(let i=0;i<55;i++){if(fa<fb){hi=b;b=a;fb=fa;a=hi-ratio*(hi-lo);fa=objective(a)}else{lo=a;a=b;fa=fb;b=lo+ratio*(hi-lo);fb=objective(b)}const h=(lo+hi)/2,cost=objective(h);if(cost<best.cost){best={h,cost};trace.push(best)}}const finalH=(lo+hi)/2;trace.push({h:finalH,cost:objective(finalH)});return {height:finalH,trace}}
function setup(id,xmin,xmax,ymin,ymax,xlabel,ylabel,unitsX=1,unitsY=1){const canvas=document.getElementById(id),w=canvas.clientWidth,h=280,dpr=devicePixelRatio||1;canvas.width=w*dpr;canvas.height=h*dpr;const g=canvas.getContext('2d');g.scale(dpr,dpr);const m={l:56,r:14,t:24,b:42},pw=w-m.l-m.r,ph=h-m.t-m.b,sx=x=>m.l+(x-xmin)/(xmax-xmin)*pw,sy=y=>h-m.b-(y-ymin)/(ymax-ymin)*ph;g.font='12px system-ui';g.strokeStyle=color('--line');g.fillStyle=color('--fg');g.strokeRect(m.l,m.t,pw,ph);for(let i=0;i<=3;i++){const x=xmin+(xmax-xmin)*i/3,y=ymin+(ymax-ymin)*i/3;g.textAlign='center';g.fillText((x*unitsX).toFixed(0),sx(x),h-m.b+18);g.textAlign='right';g.fillText((y*unitsY).toFixed(1),m.l-7,sy(y)+4)}g.textAlign='center';g.fillText(xlabel,m.l+pw/2,h-5);g.save();g.translate(14,m.t+ph/2);g.rotate(-Math.PI/2);g.fillText(ylabel,0,0);g.restore();return {g,sx,sy,m,pw,ph}}
function line(p,x1,y1,x2,y2,col,dash=[],width=2){p.g.strokeStyle=col;p.g.lineWidth=width;p.g.setLineDash(dash);p.g.beginPath();p.g.moveTo(p.sx(x1),p.sy(y1));p.g.lineTo(p.sx(x2),p.sy(y2));p.g.stroke();p.g.setLineDash([])}
function dot(p,x,y,col){p.g.fillStyle=col;p.g.beginPath();p.g.arc(p.sx(x),p.sy(y),4,0,2*Math.PI);p.g.fill()}
function draw(){cache={};const beta=Math.asin(candidate/C),corner=mode.value==='corner',rms=corner?Math.sqrt(objective(candidate))*1000:0;document.getElementById('height-label').textContent=(candidate*1000).toFixed(2)+' mm';document.getElementById('angle').textContent=(beta*180/Math.PI).toFixed(2)+'°';document.getElementById('rms').textContent=corner?rms.toFixed(3)+' mm':'未使用';
for(const v of VALIDATION){const measured=candidate-v.qx*Math.sin(beta),error=measured-v.expected;document.getElementById('block'+v.label).textContent=(measured*1000).toFixed(2)+' mm';document.getElementById('error'+v.label).textContent=(error>=0?'+':'')+(error*1000).toFixed(2)+' mm'}
const scene=setup('scene',-.025,.255,-.015,.235,'水平距离（mm）','离地高度（mm）',1000,1000);line(scene,-.025,0,.255,0,color('--line'),[],1);for(const [h,col] of [[TRUE_H,color('--true')],[candidate,color('--trial')]]){const b=Math.asin(h/C);line(scene,0,h,C*Math.cos(b),0,col);dot(scene,0,h,col);dot(scene,C*Math.cos(b),0,col)}line(scene,-.014,0,-.014,candidate,color('--trial'),[],1.5);scene.g.fillStyle=color('--fg');scene.g.textAlign='left';scene.g.fillText((candidate*1000).toFixed(1)+' mm',scene.sx(.01),scene.sy(candidate)+14);
const ymax=corner?Math.max(...profile.map(p=>p.rms))*1.13:1,cost=setup('cost',155,215,-ymax*.05,ymax,'假定安装高度（mm）','拟合残差（mm）');const {g,sx,sy}=cost;g.strokeStyle=color('--a');g.lineWidth=2;g.beginPath();profile.forEach((p,i)=>{const y=corner?p.rms:0;if(i===0)g.moveTo(sx(p.h),sy(y));else g.lineTo(sx(p.h),sy(y))});g.stroke();line(cost,TRUE_H*1000,-ymax*.05,TRUE_H*1000,ymax,color('--true'),[4,4],1);line(cost,candidate*1000,-ymax*.05,candidate*1000,rms,color('--trial'),[],1);dot(cost,candidate*1000,rms,color('--trial'));g.fillStyle=color('--fg');g.textAlign='center';g.fillText('模拟真值 181 mm',sx(TRUE_H*1000),14);}
function stop(){if(animation!==null){cancelAnimationFrame(animation);animation=null}solveButton.disabled=false;heightInput.disabled=false;mode.disabled=false}
function explain(){document.getElementById('status').textContent=mode.value==='ground'?'只有地面：改变高度时，倾角可以配合它，让地面始终落在 z=0。误差曲线是一条平线，因此无法独立求出安装高度。':'当前高度已经配上能满足地面的倾角。接下来比较不同高度能否让六个站点看到的同两面墙拼在一起；墙的位置和方向允许重新拟合。'}
heightInput.addEventListener('input',()=>{stop();candidate=Number(heightInput.value)/1000;document.getElementById('path').textContent='手动改变候选高度后，可重新开始标定。';explain();draw()});mode.addEventListener('change',()=>{stop();explain();document.getElementById('path').textContent='点击标定后显示候选高度的变化。';draw()});document.getElementById('reset').addEventListener('click',()=>{stop();candidate=.200;heightInput.value=200;explain();document.getElementById('path').textContent='已恢复 200 mm 初值。';draw()});
solveButton.addEventListener('click',()=>{stop();if(mode.value==='ground'){document.getElementById('status').textContent='无法独立标定：155–215 mm 范围内的高度都能满足地面约束，程序不能凭空选出 181 mm。请切换到“地面 + 六站点墙角”。';return}const result=solve(),initial=candidate,trail=[];solveButton.disabled=true;heightInput.disabled=true;mode.disabled=true;document.getElementById('status').textContent='正在比较候选高度：每次都重新拟合墙的位置和方向，以剩余墙面残差作为依据。';let i=0,last=0;const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;function tick(now){if(reduced){i=result.trace.length-1}else if(now-last<120){animation=requestAnimationFrame(tick);return}last=now;const p=result.trace[i++];candidate=p.h;heightInput.value=candidate*1000;trail.push((candidate*1000).toFixed(2));document.getElementById('path').textContent='候选高度（mm）：'+trail.join(' → ');draw();if(i<result.trace.length&&!reduced){animation=requestAnimationFrame(tick)}else{candidate=result.height;heightInput.value=candidate*1000;draw();stop();document.getElementById('status').textContent='标定完成：初值 '+(initial*1000).toFixed(2)+' mm → 求解高度 '+(candidate*1000).toFixed(3)+' mm。这个高度使多站点墙面残差最小；再看下方垫块的独立验证结果。'}}animation=requestAnimationFrame(tick)});
for(let i=0;i<=120;i++){const h=.155+i*.0005;profile.push({h:h*1000,rms:Math.sqrt(objective(h))*1000})}new ResizeObserver(draw).observe(document.querySelector('.plots'));matchMedia('(prefers-color-scheme: dark)').addEventListener('change',draw);explain();draw();
</script></body></html>'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="只运行高度求解验证")
    parser.add_argument("--output", type=Path, default=Path(__file__).with_suffix(".html"))
    args = parser.parse_args()
    data = geometry.make_data()
    # Independent simulated top-plane measurements, not used by solve_height.
    validation = [{"label": int(z * 1000), "expected": z,
                   "qx": geometry.GROUND_C * (1 - z / geometry.HEIGHT)}
                  for z in (0.030, 0.050)]
    solved = solve_height(data, geometry.GROUND_C)
    assert abs(solved - geometry.HEIGHT) < 1e-8
    for v in validation:
        measured = solved - v["qx"] * solved / geometry.GROUND_C
        assert abs(measured - v["expected"]) < 1e-8
    print(f"高度标定：200 mm 初值 → 数据搜索得 {solved*1000:.6f} mm")
    print("搜索没有使用模拟真值或垫块高度作为先验。")
    for h in (0.200, solved):
        error = geometry.wall_rms(data, math.asin(h / geometry.GROUND_C)) * 1000
        print(f"H={h*1000:.3f} mm，地面残差=0，墙面 RMS={error:.6f} mm")
        for v in validation:
            measured = h - v["qx"] * h / geometry.GROUND_C
            print(f"  {v['label']} mm 垫块 → {measured*1000:.3f} mm")
    if args.check:
        return
    css = geometry.HTML.split("<style>", 1)[1].split("</style>", 1)[0]
    html = HTML.replace("__CSS__", css)
    for key, value in {"__DATA__": data, "__POSES__": geometry.POSES,
                       "__C__": geometry.GROUND_C, "__TRUE_H__": geometry.HEIGHT,
                       "__VALIDATION__": validation}.items():
        html = html.replace(key, json.dumps(value, separators=(",", ":")))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(html, encoding="utf-8")
    print(f"高度标定演示已生成：{args.output.resolve()}")


if __name__ == "__main__":
    main()
