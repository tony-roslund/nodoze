import { useEffect, useId, useRef, useState } from "react";

type Size = "sm" | "md" | "lg";

const sizes = {
  sm: {
    wrap: "h-4 w-8",
    zPx: 8,
    maxX: 3,
    maxY: 2,
    pupil: 5,
    glint: 1.5,
    stroke: 2.7,
  },
  md: {
    wrap: "h-7 w-14",
    zPx: 10,
    maxX: 5,
    maxY: 4,
    pupil: 7,
    glint: 2,
    stroke: 2.5,
  },
  lg: {
    wrap: "h-24 w-40",
    zPx: 24,
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
      ? `M ${cx - 21} 13 C ${cx - 11} 8, ${cx - 2} 9, ${cx + 8} 15`
      : `M ${cx - 9} 15 C ${cx + 1} 9, ${cx + 11} 8, ${cx + 22} 13`;
  }

  return eyeIndex === 0
    ? `M ${cx - 24} 12 C ${cx - 14} 2, ${cx - 3} 2, ${cx + 8} 10`
    : `M ${cx - 8} 10 C ${cx + 3} 2, ${cx + 14} 2, ${cx + 24} 12`;
}

function tiredLinePaths(cx: number, eyeIndex: number) {
  const outer = eyeIndex === 0 ? cx - 28 : cx + 28;
  const direction = eyeIndex === 0 ? -1 : 1;

  if (eyeIndex === 0) {
    return [
      `M ${cx - 18} 80 C ${cx - 7} 88, ${cx + 10} 86, ${cx + 19} 78`,
      `M ${cx - 12} 87 C ${cx - 2} 92, ${cx + 7} 91, ${cx + 15} 84`,
      `M ${outer} 56 L ${outer + direction * 10} 52`,
      `M ${outer + 1} 64 L ${outer + direction * 12} 64`,
      `M ${outer + 1} 72 L ${outer + direction * 9} 78`,
    ];
  }

  return [
    `M ${cx - 19} 78 C ${cx - 8} 86, ${cx + 7} 89, ${cx + 18} 80`,
    `M ${cx - 15} 84 C ${cx - 6} 91, ${cx + 3} 92, ${cx + 12} 87`,
    `M ${outer} 55 L ${outer + direction * 8} 50`,
    `M ${outer - 1} 63 L ${outer + direction * 11} 61`,
    `M ${outer - 1} 71 L ${outer + direction * 10} 75`,
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
  const lidColor = "#fffdf7";

  return (
    <span ref={ref} className={`relative inline-flex ${config.wrap} shrink-0`} aria-hidden="true">
      {!enabled ? (
        <>
          <span className="sr-only">Zzz</span>
          <span className="pointer-events-none absolute inset-0 z-0 text-current opacity-80" aria-hidden="true">
            <span
              className="absolute font-bold tracking-normal [animation:nodoze-sleep-float_2.4s_ease-in-out_infinite]"
              style={{ top: "-10%", left: "50%", fontSize: config.zPx }}
            >
              Z
            </span>
            <span
              className="absolute font-bold tracking-normal [animation:nodoze-sleep-float_2.4s_ease-in-out_infinite] [animation-delay:220ms]"
              style={{ top: "-20%", left: "59%", fontSize: config.zPx * 0.82 }}
            >
              z
            </span>
            <span
              className="absolute font-bold tracking-normal [animation:nodoze-sleep-float_2.4s_ease-in-out_infinite] [animation-delay:440ms]"
              style={{ top: "-30%", left: "67%", fontSize: config.zPx * 0.72 }}
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
              <ellipse cx={cx} cy={eyeY} rx={eyeRx} ry={eyeRy} />
            </clipPath>
          ))}
        </defs>

        {eyeCenters.map((cx, index) => {
          const crossX = offset.crossed ? (index === 0 ? config.maxX * 0.8 : -config.maxX * 0.8) : offset.x;
          const pupilX = cx + (enabled ? crossX : index === 0 ? -2 : 2);
          const pupilY = eyeY + (enabled ? offset.y : 13);

          return (
            <g key={cx}>
              <path
                d={browPath(cx, index, enabled)}
                stroke="#111113"
                strokeWidth={config.stroke * 1.45}
                strokeLinecap="round"
              />
              <ellipse
                cx={cx}
                cy={eyeY}
                rx={eyeRx}
                ry={eyeRy}
                fill="#fffdf7"
                stroke="#18181b"
                strokeOpacity="0.88"
                strokeWidth={config.stroke}
              />
              <g clipPath={`url(#${clipId}-${cx})`}>
                <circle cx={pupilX} cy={pupilY} r={config.pupil} fill="#111113" />
                <circle cx={pupilX - config.glint} cy={pupilY - config.glint} r={config.glint} fill="white" fillOpacity="0.92" />
                <path d={lowerLidPath(cx)} fill="#fffdf7" />
                <path d={upperLidPath(cx, openness)} fill={lidColor} />
              </g>
              {!enabled
                ? tiredLinePaths(cx, index).map((path) => (
                    <path
                      key={path}
                      d={path}
                      stroke="#111113"
                      strokeOpacity="0.55"
                      strokeWidth={config.stroke * 0.72}
                      strokeLinecap="round"
                    />
                  ))
                : null}
              <path
                d={upperLidEdgePath(cx, openness)}
                stroke="#111113"
                strokeOpacity={enabled && !blinking ? "0.3" : "0.9"}
                strokeWidth={enabled && !blinking ? config.stroke * 0.8 : config.stroke * 1.1}
                strokeLinecap="round"
              />
              <path
                d={creasePath(cx, openness, index)}
                stroke="#111113"
                strokeOpacity={enabled ? "0.18" : "0.52"}
                strokeWidth={enabled ? config.stroke * 0.8 : config.stroke * 0.95}
                strokeLinecap="round"
              />
              <path
                d={`M ${cx - 22} ${eyeY + eyeRy - 6} C ${cx - 8} ${eyeY + eyeRy + 2}, ${cx + 8} ${eyeY + eyeRy + 2}, ${cx + 22} ${eyeY + eyeRy - 6}`}
                stroke="#111113"
                strokeOpacity="0.22"
                strokeWidth={config.stroke * 0.75}
                strokeLinecap="round"
              />
            </g>
          );
        })}
      </svg>
    </span>
  );
}
