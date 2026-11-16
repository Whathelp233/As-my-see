#!/usr/bin/env python3
"""Pitch / installation-height observability demo; Python standard library only.

Run:
  python3 line_laser_pitch_observability.py
  python3 line_laser_pitch_observability.py --check

The generated HTML is offline and interactive. This is a controlled geometry
demo: point-to-wall labels and robot poses are known, yaw/xy are held fixed,
and each unknown vertical wall is freely refitted for every trial pitch.
It is NOT the full 6-DOF corner calibration or a sensor-accuracy benchmark.
Angles use a right-handed Ry(beta): positive beta points the laser x axis down.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

HEIGHT = 0.181
GROUND_C = 0.2428
TRUE_PITCH = math.asin(HEIGHT / GROUND_C)
WRONG_PITCH = math.asin(0.200 / GROUND_C)
# Synthetic teaching values only; they are not sensor specifications.
LASER_YAW = math.pi / 4
WALL_X = WALL_Y = 0.120
POSES = [(0, 0, 0), (0.030, 0, 0), (-0.020, 0.025, -15),
         (0.020, -0.020, 15), (-0.030, -0.030, 8), (0.020, 0.020, -8)]


def rotate_xy(x, y, yaw):
    return (x * math.cos(yaw) - y * math.sin(yaw),
            x * math.sin(yaw) + y * math.cos(yaw))


def make_data():
    """Raycast 200 beams against a floor and two walls at each pose."""
    data = []
    for i, (px, py, yaw_deg) in enumerate(POSES):
        yaw = LASER_YAW + math.radians(yaw_deg)
        for k in range(200):
            theta = math.radians(-57.5 + 115 * k / 199)
            dx, dy = rotate_xy(math.cos(TRUE_PITCH) * math.cos(theta),
                               math.sin(theta), yaw)
            dz = -math.sin(TRUE_PITCH) * math.cos(theta)
            hits = [(-HEIGHT / dz, "ground")]
            if dx > 1e-9:
                hits.append(((WALL_X - px) / dx, "A"))
            if dy > 1e-9:
                hits.append(((WALL_Y - py) / dy, "B"))
            r, wall = min((r, wall) for r, wall in hits if r > 0)
            # Mimic using only clean, raised wall traces; ground is separate.
            z = HEIGHT + r * dz
            if wall == "ground" or z < 0.035:
                continue
            data.append({"station": i, "wall": wall,
                         "qx": r * math.cos(theta), "qy": r * math.sin(theta)})
    return data


def reconstruct(point, beta):
    px, py, yaw = POSES[point["station"]]
    x, y = rotate_xy(point["qx"] * math.cos(beta), point["qy"],
                     LASER_YAW + math.radians(yaw))
    return x + px, y + py


def fit_line(points):
    """Free 2D TLS fit: a vertical wall has arbitrary direction AND offset."""
    n = len(points)
    mx = sum(x for x, _ in points) / n
    my = sum(y for _, y in points) / n
    xx = sum((x - mx) ** 2 for x, _ in points) / n
    yy = sum((y - my) ** 2 for _, y in points) / n
    xy = sum((x - mx) * (y - my) for x, y in points) / n
    tangent = 0.5 * math.atan2(2 * xy, xx - yy)
    nx, ny = -math.sin(tangent), math.cos(tangent)
    offset = nx * mx + ny * my
    errors = [nx * x + ny * y - offset for x, y in points]
    return math.sqrt(sum(e * e for e in errors) / n)


def wall_rms(data, beta, multi=True):
    groups = [[reconstruct(p, beta) for p in data
               if p["wall"] == wall and (multi or p["station"] == 0)]
              for wall in ("A", "B")]
    count = sum(map(len, groups))
    return math.sqrt(sum(len(g) * fit_line(g) ** 2 for g in groups) / count)


def check(data):
    # Validate the identities that the explanation depends on.
    assert all(sum(p["wall"] == wall and p["station"] == i for p in data) >= 5
               for i in range(len(POSES)) for wall in ("A", "B"))
    assert wall_rms(data, TRUE_PITCH) < 1e-10
    assert wall_rms(data, WRONG_PITCH, multi=False) < 1e-10
    assert wall_rms(data, WRONG_PITCH, multi=True) > 0.001
    for beta in (TRUE_PITCH, WRONG_PITCH, math.radians(40)):
        h = GROUND_C * math.sin(beta)
        for theta in (-0.9, 0.0, 0.9):
            ground_range = GROUND_C / math.cos(theta)
            z = h - ground_range * math.cos(theta) * math.sin(beta)
            assert abs(z) < 1e-12
    qx, qy = 0.15, 0.06
    assert abs(qx * math.cos(TRUE_PITCH) - qx * math.cos(WRONG_PITCH)) > 0.01
    assert rotate_xy(qx * math.cos(TRUE_PITCH), qy, 0)[1] == qy
    assert rotate_xy(qx * math.cos(WRONG_PITCH), qy, 0)[1] == qy
    # Two forward-translated poses see the SAME unknown front wall.
    displacement, d = 0.050, 0.140
    r1, r2 = d / math.cos(TRUE_PITCH), (d - displacement) / math.cos(TRUE_PITCH)
    recovered = math.acos(displacement / (r1 - r2))
    assert abs(recovered - TRUE_PITCH) < 1e-12
    wrong_walls = (r1 * math.cos(WRONG_PITCH), displacement + r2 * math.cos(WRONG_PITCH))
    print(f"真实 pitch: {math.degrees(TRUE_PITCH):.4f} deg; 高度: 181 mm")
    print(f"错误 pitch: {math.degrees(WRONG_PITCH):.4f} deg; 高度: 200 mm")
    print("墙位置与方向都允许重新拟合：")
    print(f"  单站点 / 错误 pitch: RMS = {wall_rms(data, WRONG_PITCH, False)*1000:.6f} mm")
    print(f"  六站点 / 错误 pitch: RMS = {wall_rms(data, WRONG_PITCH)*1000:.3f} mm")
    print(f"  六站点 / 正确 pitch: RMS = {wall_rms(data, TRUE_PITCH)*1000:.6f} mm")
    print("简化前墙例子：机器人向前移动 50 mm，墙位置未知。")
    print(f"  两次中央束距离: {r1*1000:.3f}, {r2*1000:.3f} mm")
    print(f"  cos(beta) = 50 / ({r1*1000:.3f} - {r2*1000:.3f})")
    print(f"  解得 pitch = {math.degrees(recovered):.4f} deg")
    print(f"  用错误 pitch 重建同一面墙的位置: {wrong_walls[0]*1000:.3f}, {wrong_walls[1]*1000:.3f} mm")
    print(f"  同一面墙被算到两个位置，相差 {(wrong_walls[1]-wrong_walls[0])*1000:.3f} mm")
    print("PASS: 投影、单站点歧义、多站点约束、两次距离差公式均已检查。")


HTML = r'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pitch 为什么会改变水平位置</title>
<style>
:root{color-scheme:light dark;--bg:light-dark(#fafafa,#15181c);--fg:light-dark(#20242b,#e6e9ef);--muted:light-dark(#565f70,#a9b2c2);--line:light-dark(#ccd1db,#475160);--true:light-dark(#067256,#66d6b5);--trial:light-dark(#ba4a16,#ffad75);--a:light-dark(#2e60b2,#87b2ff);--b:light-dark(#a33c80,#ec9bd4)}
*{box-sizing:border-box}body{background:var(--bg);color:var(--fg);font:16px/1.65 system-ui,sans-serif;margin:0;padding:24px}main{max-width:1000px;margin:auto}h1{font-size:26px}h2{font-size:20px;margin-top:28px}p{margin:10px 0}button,select,input{font:inherit}button,select{padding:7px 12px;color:var(--fg);background:var(--bg);border:1px solid var(--line);border-radius:6px}button:focus-visible,select:focus-visible,input:focus-visible{outline:2px solid var(--a);outline-offset:3px}button{cursor:pointer}.controls{display:flex;gap:12px;align-items:center;flex-wrap:wrap}.slider{width:100%;margin:12px 0}.metrics{display:flex;gap:24px;flex-wrap:wrap;font-variant-numeric:tabular-nums}.muted{color:var(--muted)}.plots{display:grid;grid-template-columns:1fr 1fr;gap:24px}.plot{min-width:0}canvas{width:100%;height:330px;display:block}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:light-dark(#f0f2f5,#222831);padding:14px;border-radius:6px;font:14px/1.7 ui-monospace,monospace}.legend{display:flex;gap:16px;flex-wrap:wrap}.swatch{display:inline-block;width:20px;height:3px;vertical-align:middle;margin-right:5px}.true{background:var(--true)}.trial{background:var(--trial)}.a{background:var(--a)}.b{background:var(--b)}.result{min-height:52px}table{width:100%;border-collapse:collapse;font-variant-numeric:tabular-nums}td,th{text-align:left;padding:7px;border-bottom:1px solid var(--line)}@media(max-width:700px){body{padding:16px}.plots{grid-template-columns:1fr}h1{font-size:22px}}
</style></head><body><main>
<h1>Pitch 改变的是点的水平投影</h1>
<p>激光测到的斜距不变，转动安装角度后，这段斜距在水平方向和竖直方向的分配会改变。这里的正 pitch 表示向下倾斜。</p>
<div class="controls"><label for="mode">墙面观测</label><select id="mode"><option value="multi">六个位置：转向 + 平移</option><option value="single">只看第一个位置</option></select><button id="correct">正确：181 mm</button><button id="wrong">错误：200 mm</button></div>
<label for="pitch">假定 pitch：<strong id="angle"></strong></label><input class="slider" id="pitch" type="range" min="35" max="65" step="0.01" aria-label="假定 pitch，单位度">
<div class="metrics" aria-live="polite"><span>对应安装高度：<strong id="height"></strong></span><span>地面 z 残差：<strong>0 mm</strong></span><span>自由拟合墙面 RMS：<strong id="rms"></strong></span></div>
<p class="result" id="result" aria-live="polite"></p>
<div class="plots"><div class="plot"><h2>侧视：地面仍然能凑对</h2><div class="legend"><span><i class="swatch true"></i>真实角度</span><span><i class="swatch trial"></i>假定角度</span></div><canvas id="side" role="img" aria-label="中央激光束侧视图，比较真实和假定安装高度及地面落点"></canvas></div><div class="plot"><h2>俯视：同一面墙能否拼到一起</h2><div class="legend"><span><i class="swatch a"></i>墙 A</span><span><i class="swatch b"></i>墙 B</span><span>实线＝重新拟合的墙；点形状＝站点</span></div><canvas id="top" role="img" aria-label="墙面点俯视图，墙面方向与位置均允许重新拟合"></canvas></div></div>
<p class="muted">这是无噪声的简化几何演示：机器人位姿、点属于哪面墙已知；只改变 pitch，并按地面约束联动高度。墙的位置和方向均自由拟合。真实 corner 还同时求 x/y/yaw/roll，并处理测距噪声和点分类。</p>
<h2>公式一：为什么水平位置会变</h2>
<pre>绕 y 轴转动 beta：
x_B = x_L cos(beta) + z_L sin(beta) + t_x
y_B = y_L + t_y
z_B = -x_L sin(beta) + z_L cos(beta) + H

扫描点在激光 XY 平面内：z_L = 0，x_L = r cos(theta)
因此：x_B = r cos(theta) cos(beta) + t_x
      y_B = r sin(theta) + t_y
      z_B = H - r cos(theta) sin(beta)

水平 x 会变，y 不变；theta = ±90° 的束不受这个 pitch 影响。
从 beta = 0° 出发，小角度的水平变化是二阶量，可能很难看出来。
真实驱动若含 roll = 180°，y 项会换符号，但 x 的 cos(beta) 关系仍成立。</pre>
<h2>公式二：为什么地面可以凑对</h2>
<pre>地面线的面内距离 c = 242.8 mm。
只要设置 H = c sin(beta)，地面点就始终满足 z_B = 0。

beta = 48.1994° → H = 181 mm
beta = 55.4593° → H = 200 mm

两组都满足地面约束，但水平投影 c cos(beta) 不同。
地面是一整块平面，没有已知水平坐标的标记点，所以仅靠地面无法排除其中一组。</pre>
<h2>公式三：不用知道墙距，两次测量也能约束 pitch</h2>
<p>单独考虑正前方的一面墙和中央束。机器人朝墙移动 50 mm，朝向不变。墙实际在起点前方 140 mm，但解算时不需要知道这个数。</p>
<pre>第一次：D = t_x + r1 cos(beta)
第二次：D = 50 + t_x + r2 cos(beta)
相减：  cos(beta) = 50 / (r1 - r2)

r1 = 210.040 mm，r2 = 135.026 mm
解得 beta = 48.1994°，再用 H = c sin(beta) 得到 181 mm。

如果错误地使用 beta = 55.4593°：
第一次把墙算在 X = 119.091 mm
第二次把墙算在 X = 126.559 mm
同一面固定墙相差 7.467 mm，重新选一个墙距也无法同时消掉这个差。

如果只看侧墙 y = 常数，单纯改变 pitch 不改变 y，确实可能看不出来。
本例说明某个 pitch 可以被约束，不代表纯平移能解出完整 6 自由度外参。</pre>
<p class="muted">前墙例子的已知 50 mm 位移提供了关键约束。若机器人位移尺度本身错了，推算的 pitch 和安装高度也会受到影响。演示角度采用相对水平面的倾角，不使用现有代码中误标为面地夹角的余角。</p>
</main><script>
const DATA = __DATA__;
const POSES = __POSES__;
const H0=.181,C=.2428,B0=Math.asin(H0/C),BW=Math.asin(.2/C),LY=Math.PI/4;
const pitch=document.getElementById('pitch'),mode=document.getElementById('mode');
let colorCache={};
function color(name){if(!colorCache[name]){const probe=document.createElement('span');probe.style.color='var('+name+')';document.body.appendChild(probe);colorCache[name]=getComputedStyle(probe).color;probe.remove()}return colorCache[name]}
function xy(p,b){const pose=POSES[p.station],a=LY+pose[2]*Math.PI/180,x=p.qx*Math.cos(b),y=p.qy;return {x:pose[0]+x*Math.cos(a)-y*Math.sin(a),y:pose[1]+x*Math.sin(a)+y*Math.cos(a),wall:p.wall,station:p.station}}
function fit(points){const n=points.length,mx=points.reduce((s,p)=>s+p.x,0)/n,my=points.reduce((s,p)=>s+p.y,0)/n;let xx=0,yy=0,xy=0;for(const p of points){const x=p.x-mx,y=p.y-my;xx+=x*x/n;yy+=y*y/n;xy+=x*y/n}const a=.5*Math.atan2(2*xy,xx-yy),nx=-Math.sin(a),ny=Math.cos(a),d=nx*mx+ny*my;const mse=points.reduce((s,p)=>s+(nx*p.x+ny*p.y-d)**2,0)/n;return {mx,my,tx:Math.cos(a),ty:Math.sin(a),mse}}
function setup(id,xmin,xmax,ymin,ymax,xlabel,ylabel){const canvas=document.getElementById(id),w=canvas.clientWidth,h=330,dpr=window.devicePixelRatio||1;canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);const g=canvas.getContext('2d');g.scale(dpr,dpr);const m={l:58,r:14,t:18,b:44},pw=w-m.l-m.r,ph=h-m.t-m.b;const sx=x=>m.l+(x-xmin)/(xmax-xmin)*pw,sy=y=>h-m.b-(y-ymin)/(ymax-ymin)*ph;g.font='12px system-ui';g.strokeStyle=color('--line');g.fillStyle=color('--fg');g.lineWidth=1;g.strokeRect(m.l,m.t,pw,ph);for(let i=0;i<=3;i++){const x=xmin+(xmax-xmin)*i/3,y=ymin+(ymax-ymin)*i/3;g.textAlign='center';g.fillText((x*1000).toFixed(0),sx(x),h-m.b+19);g.textAlign='right';g.fillText((y*1000).toFixed(0),m.l-8,sy(y)+4)}g.textAlign='center';g.fillText(xlabel,m.l+pw/2,h-7);g.save();g.translate(14,m.t+ph/2);g.rotate(-Math.PI/2);g.fillText(ylabel,0,0);g.restore();return {g,sx,sy,m,pw,ph,w,h}}
function line(plot,x1,y1,x2,y2,stroke,dash=[],width=2){const {g,sx,sy}=plot;g.strokeStyle=stroke;g.lineWidth=width;g.setLineDash(dash);g.beginPath();g.moveTo(sx(x1),sy(y1));g.lineTo(sx(x2),sy(y2));g.stroke();g.setLineDash([])}
function mark(plot,x,y,stroke,station=0,size=3){const {g,sx,sy}=plot,a=sx(x),b=sy(y);g.fillStyle=stroke;g.strokeStyle=stroke;g.lineWidth=1.5;g.beginPath();if(station%3===0){g.arc(a,b,size,0,2*Math.PI);g.fill()}else if(station%3===1){g.rect(a-size,b-size,2*size,2*size);g.stroke()}else{g.moveTo(a,b-size-1);g.lineTo(a+size+1,b+size);g.lineTo(a-size-1,b+size);g.closePath();g.stroke()}if(station>=3){g.beginPath();g.moveTo(a-size,b);g.lineTo(a+size,b);g.stroke()}}
function draw(){colorCache={};const beta=Number(pitch.value)*Math.PI/180,height=C*Math.sin(beta),multi=mode.value==='multi';const points=DATA.filter(p=>multi||p.station===0).map(p=>xy(p,beta));const groups=['A','B'].map(w=>points.filter(p=>p.wall===w)),fits=groups.map(fit);const rms=Math.sqrt(groups.reduce((s,ps,i)=>s+ps.length*fits[i].mse,0)/points.length)*1000;document.getElementById('angle').textContent=(beta*180/Math.PI).toFixed(2)+'°';document.getElementById('height').textContent=(height*1000).toFixed(2)+' mm';document.getElementById('rms').textContent=rms.toFixed(3)+' mm';document.getElementById('result').textContent=!multi?'单站点：换了 pitch 后，两段墙迹线仍能各自拟合成一面竖直墙，无法仅凭这一站排除错误。':rms<.01?'多站点：这组 pitch 能让各站点的墙迹线共同落在同两面墙上。':'多站点：墙的位置和方向已经重新拟合，仍有残差；各站点对同一面墙的解释不一致。';
const side=setup('side',-.015,.255,-.02,.24,'水平 X（mm）','高度 Z（mm）');line(side,-.015,0,.255,0,color('--line'));for(const [b,h,col] of [[B0,H0,color('--true')],[beta,height,color('--trial')]]){line(side,0,h,C*Math.cos(b),0,col);mark(side,0,h,col,0,4);mark(side,C*Math.cos(b),0,col,0,4)}
const top=setup('top',-.085,.23,-.085,.23,'参考系 X（mm）','参考系 Y（mm）');const {g,sx,sy,m,pw,ph}=top;g.save();g.beginPath();g.rect(m.l,m.t,pw,ph);g.clip();for(let i=0;i<2;i++){const f=fits[i],col=color(i===0?'--a':'--b');line(top,f.mx-f.tx,f.my-f.ty,f.mx+f.tx,f.my+f.ty,col,[],1.5)}for(const p of points)mark(top,p.x,p.y,color(p.wall==='A'?'--a':'--b'),p.station,2.4);POSES.forEach((p,i)=>{if(multi||i===0){mark(top,p[0],p[1],color('--muted'),i,4);g.fillStyle=color('--fg');g.fillText(String(i+1),sx(p[0])+10,sy(p[1])-7)}});g.restore();}
pitch.value=(BW*180/Math.PI).toFixed(6);pitch.addEventListener('input',draw);mode.addEventListener('change',draw);document.getElementById('correct').addEventListener('click',()=>{pitch.value=(B0*180/Math.PI).toFixed(6);draw()});document.getElementById('wrong').addEventListener('click',()=>{pitch.value=(BW*180/Math.PI).toFixed(6);draw()});new ResizeObserver(draw).observe(document.querySelector('.plots'));window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change',draw);draw();
</script></body></html>'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="仅运行几何验证并输出数值")
    parser.add_argument("--output", type=Path, default=Path(__file__).with_suffix(".html"))
    args = parser.parse_args()
    data = make_data()
    check(data)
    if not args.check:
        text = HTML.replace("__DATA__", json.dumps(data, separators=(",", ":")))
        text = text.replace("__POSES__", json.dumps(POSES))
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
        print(f"离线交互演示已生成：{args.output.resolve()}")


if __name__ == "__main__":
    main()
