import { useEffect, useId, useRef, useState } from "react";

type Size = "sm" | "md" | "lg";

const sizes = {
  sm: {
    wrap: "h-4 w-8",
    zPx: 10,
    maxX: 3,
    maxY: 2,
    pupil: 5,
    glint: 1.5,
    stroke: 2.7,
  },
  md: {
    wrap: "h-7 w-14",
    zPx: 16,
    maxX: 5,
    maxY: 4,
    pupil: 7,
    glint: 2,
    stroke: 2.5,
  },
  lg: {
    wrap: "h-24 w-40",
    zPx: 30,
    maxX: 12,
    maxY: 10,
    pupil: 14,
    glint: 4,
    stroke: 2,
  },
};

const eyeCenters = [44, 100];
const eyeY = 48;
const eyeRx = 28;
const eyeRy = 36;

function upperLidPath(cx: number, openness: number) {
  const closedness = 1 - openness;
  const sideY = eyeY - eyeRy + 10 + closedness * 27;
  const centerY = eyeY - eyeRy + 6 + closedness * 61;

  return [
    `M ${cx - eyeRx - 4} ${eyeY - eyeRy - 12}`,
    `L ${cx + eyeRx + 4} ${eyeY - eyeRy - 12}`,
    `L ${cx + eyeRx + 4} ${sideY}`,
    `C ${cx + 22} ${centerY + 2}, ${cx - 21} ${centerY - 1}, ${cx - eyeRx - 4} ${sideY}`,
    "Z",
  ].join(" ");
}

function upperLidEdgePath(cx: number, openness: number) {
  const closedness = 1 - openness;
  const sideY = eyeY - eyeRy + 10 + closedness * 27;
  const centerY = eyeY - eyeRy + 6 + closedness * 61;
  return `M ${cx - eyeRx - 4} ${sideY} C ${cx - 21} ${centerY - 1}, ${cx + 22} ${centerY + 2}, ${cx + eyeRx + 4} ${sideY}`;
}

function lowerLidPath(cx: number) {
  return [
    `M ${cx - eyeRx - 1} ${eyeY + eyeRy - 7}`,
    `C ${cx - 15} ${eyeY + eyeRy + 3}, ${cx + 15} ${eyeY + eyeRy + 3}, ${cx + eyeRx + 1} ${eyeY + eyeRy - 7}`,
    `L ${cx + eyeRx + 1} ${eyeY + eyeRy + 7}`,
    `L ${cx - eyeRx - 1} ${eyeY + eyeRy + 7}`,
    "Z",
  ].join(" ");
}

function creasePath(cx: number, openness: number, eyeIndex: number) {
  const y = eyeY - eyeRy + 10 + (1 - openness) * 16;
  const leftLift = eyeIndex === 0 ? 2 : -1;
  const rightLift = eyeIndex === 0 ? -1 : 2;
  return `M ${cx - 21} ${y + leftLift} C ${cx - 9} ${y - 9}, ${cx + 9} ${y - 8}, ${cx + 21} ${y + rightLift}`;
}

function browPath(cx: number, eyeIndex: number, enabled: boolean) {
  if (!enabled) {
    return eyeIndex === 0
      ? `M ${cx - 28} 25 C ${cx - 14} 8, ${cx + 5} 8, ${cx + 25} 31`
      : `M ${cx - 25} 31 C ${cx - 5} 8, ${cx + 14} 8, ${cx + 28} 25`;
  }

  return eyeIndex === 0
    ? `M ${cx - 24} 12 C ${cx - 14} 2, ${cx - 3} 2, ${cx + 8} 10`
    : `M ${cx - 8} 10 C ${cx + 3} 2, ${cx + 14} 2, ${cx + 24} 12`;
}

function tiredEyePath(cx: number, eyeIndex: number) {
  return eyeIndex === 0
    ? `M ${cx - 33} 53 C ${cx - 28} 30, ${cx - 3} 17, ${cx + 31} 43 C ${cx + 23} 66, ${cx - 15} 71, ${cx - 33} 53 Z`
    : `M ${cx - 31} 43 C ${cx + 3} 17, ${cx + 28} 30, ${cx + 33} 53 C ${cx + 15} 71, ${cx - 23} 66, ${cx - 31} 43 Z`;
}

function tiredLidPath(cx: number, eyeIndex: number) {
  return eyeIndex === 0
    ? `M ${cx - 35} 53 C ${cx - 15} 47, ${cx + 8} 43, ${cx + 32} 42`
    : `M ${cx - 32} 42 C ${cx - 8} 43, ${cx + 15} 47, ${cx + 35} 53`;
}

function tiredLidFillPath(cx: number, eyeIndex: number) {
  return eyeIndex === 0
    ? `M ${cx - 35} 53 C ${cx - 15} 47, ${cx + 8} 43, ${cx + 32} 42 L ${cx + 36} -12 L ${cx - 36} -12 Z`
    : `M ${cx - 32} 42 C ${cx - 8} 43, ${cx + 15} 47, ${cx + 35} 53 L ${cx + 36} -12 L ${cx - 36} -12 Z`;
}

function tiredLinePaths(cx: number, eyeIndex: number) {
  return [
    eyeIndex === 0
      ? `M ${cx - 22} 69 C ${cx - 9} 75, ${cx + 9} 75, ${cx + 24} 66`
      : `M ${cx - 24} 66 C ${cx - 9} 75, ${cx + 9} 75, ${cx + 22} 69`,
  ];
}

export function GooglyEyes({ enabled = true, size = "md" }: { enabled?: boolean; size?: Size }) {
  const ref = useRef<HTMLSpanElement>(null);
  const clipId = useId();
  const [offset, setOffset] = useState({ x: 0, y: 0, crossed: false });
  const [blinking, setBlinking] = useState(false);
  const config = sizes[size];

  useEffect(() => {
    function onMove(event: MouseEvent) {
      const element = ref.current;
      if (!element) {
        return;
      }

      const rect = element.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      const dx = event.clientX - centerX;
      const dy = event.clientY - centerY;
      const distance = Math.hypot(dx, dy) || 1;
      const near = distance < rect.width * 0.95;
      const strength = Math.min(distance / (rect.width * 0.75), 1);

      setOffset({
        x: (dx / distance) * config.maxX * strength,
        y: (dy / distance) * config.maxY * strength,
        crossed: near,
      });
    }

    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, [config.maxX, config.maxY]);

  useEffect(() => {
    if (!enabled) {
      return;
    }

    const interval = window.setInterval(() => {
      setBlinking(true);
      window.setTimeout(() => setBlinking(false), 140);
    }, 5200);

    return () => window.clearInterval(interval);
  }, [enabled]);

  const openness = blinking ? 0.02 : enabled ? 0.98 : 0.14;
  const eyeColor = "#fffdf7";
  const lidColor = enabled && !blinking ? eyeColor : "#ded5c6";

  return (
    <span ref={ref} className={`relative inline-flex ${config.wrap} shrink-0`} aria-hidden="true">
      {!enabled ? (
        <>
          <span className="sr-only">Zzz</span>
          <span className="pointer-events-none absolute inset-0 z-20 text-current opacity-95" aria-hidden="true">
            <span
              className="nodoze-zzz absolute font-bold tracking-normal [animation:nodoze-sleep-float_2.8s_ease-in-out_infinite] [animation-delay:-900ms]"
              style={{ top: "-6%", left: "48%", fontSize: config.zPx }}
            >
              Z
            </span>
            <span
              className="nodoze-zzz absolute font-bold tracking-normal [animation:nodoze-sleep-float_2.8s_ease-in-out_infinite] [animation-delay:-360ms]"
              style={{ top: "-19%", left: "62%", fontSize: config.zPx * 0.78 }}
            >
              z
            </span>
            <span
              className="nodoze-zzz absolute font-bold tracking-normal [animation:nodoze-sleep-float_2.8s_ease-in-out_infinite] [animation-delay:260ms]"
              style={{ top: "-31%", left: "73%", fontSize: config.zPx * 0.68 }}
            >
              z
            </span>
          </span>
        </>
      ) : null}
      <svg viewBox="0 0 144 96" className="relative z-10 size-full overflow-visible" fill="none">
        <defs>
          {eyeCenters.map((cx) => (
            <clipPath key={cx} id={`${clipId}-${cx}`}>
              {enabled ? <ellipse cx={cx} cy={eyeY} rx={eyeRx} ry={eyeRy} /> : <path d={tiredEyePath(cx, eyeCenters.indexOf(cx))} />}
            </clipPath>
          ))}
        </defs>

        {eyeCenters.map((cx, index) => {
          const crossX = offset.crossed ? (index === 0 ? config.maxX * 0.8 : -config.maxX * 0.8) : offset.x;
          const pupilX = cx + (enabled ? crossX : index === 0 ? 8 : -8);
          const pupilY = eyeY + (enabled ? offset.y : 1);
          const pupilRadius = enabled ? config.pupil : config.pupil * 0.44;

          return (
            <g key={cx}>
              <path
                d={browPath(cx, index, enabled)}
                stroke="#111113"
                strokeWidth={config.stroke * 1.45}
                strokeLinecap="round"
              />
              {enabled ? (
                <ellipse
                  cx={cx}
                  cy={eyeY}
                  rx={eyeRx}
                  ry={eyeRy}
                  fill={eyeColor}
                  stroke="#18181b"
                  strokeOpacity="0.88"
                  strokeWidth={config.stroke}
                />
              ) : (
                <path d={tiredEyePath(cx, index)} fill={eyeColor} stroke="#18181b" strokeOpacity="0.88" strokeWidth={config.stroke} />
              )}
              <g clipPath={`url(#${clipId}-${cx})`}>
                <circle cx={pupilX} cy={pupilY} r={pupilRadius} fill="#111113" />
                {enabled ? <circle cx={pupilX - config.glint} cy={pupilY - config.glint} r={config.glint} fill="white" fillOpacity="0.92" /> : null}
                {enabled ? (
                  <>
                    <path d={lowerLidPath(cx)} fill={eyeColor} />
                    <path d={upperLidPath(cx, openness)} fill={lidColor} />
                  </>
                ) : (
                  <path d={tiredLidFillPath(cx, index)} fill={lidColor} />
                )}
              </g>
              {!enabled
                ? tiredLinePaths(cx, index).map((path) => (
                    <path
                      key={path}
                      d={path}
                      stroke="#111113"
                      strokeOpacity="0.28"
                      strokeWidth={config.stroke * 0.75}
                      strokeLinecap="round"
                    />
                  ))
                : null}
              {enabled ? (
                <path
                  d={upperLidEdgePath(cx, openness)}
                  stroke="#111113"
                  strokeOpacity={enabled && !blinking ? "0.3" : "0.9"}
                  strokeWidth={enabled && !blinking ? config.stroke * 0.8 : config.stroke * 1.1}
                  strokeLinecap="round"
                />
              ) : (
                <path d={tiredLidPath(cx, index)} stroke="#111113" strokeOpacity="0.92" strokeWidth={config.stroke * 1.25} strokeLinecap="round" />
              )}
              <path
                d={creasePath(cx, openness, index)}
                stroke="#111113"
                strokeOpacity={enabled ? "0.18" : "0"}
                strokeWidth={config.stroke * 0.8}
                strokeLinecap="round"
              />
              {enabled ? (
                <path
                  d={`M ${cx - 22} ${eyeY + eyeRy - 6} C ${cx - 8} ${eyeY + eyeRy + 2}, ${cx + 8} ${eyeY + eyeRy + 2}, ${cx + 22} ${eyeY + eyeRy - 6}`}
                  stroke="#111113"
                  strokeOpacity="0.22"
                  strokeWidth={config.stroke * 0.75}
                  strokeLinecap="round"
                />
              ) : null}
            </g>
          );
        })}
      </svg>
    </span>
  );
}
