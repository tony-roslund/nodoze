import type { ReactNode } from "react";
import { useState } from "react";

type AnimatedIconTooltipProps = {
  label: string;
  detail?: string;
  children: ReactNode;
};

export function AnimatedIconTooltip({ label, detail, children }: AnimatedIconTooltipProps) {
  const [showTooltip, setShowTooltip] = useState(false);

  function resetTooltip() {
    setShowTooltip(false);
  }

  return (
    <span
      onBlur={resetTooltip}
      onFocus={() => setShowTooltip(true)}
      onMouseEnter={() => setShowTooltip(true)}
      onMouseLeave={resetTooltip}
      className="relative inline-flex"
    >
      <span
        role="tooltip"
        className={[
          "pointer-events-none absolute bottom-full left-1/2 z-40 mb-2 hidden whitespace-nowrap rounded-sm bg-zinc-950 px-2.5 py-1.5 text-center shadow-[0_12px_30px_rgb(0_0_0/0.16)] sm:block",
          showTooltip ? "scale-100 opacity-100" : "scale-[0.88] opacity-0",
        ].join(" ")}
        style={{
          transform: `translateX(-50%) translateY(${showTooltip ? 0 : 8}px) scale(${showTooltip ? 1 : 0.92})`,
          transition:
            "opacity 160ms cubic-bezier(0.2, 0.8, 0.2, 1), transform 220ms cubic-bezier(0.2, 0.8, 0.2, 1)",
        }}
      >
        <span className="block text-[11px] leading-tight font-medium text-[#f7f7f4]">{label}</span>
        {detail ? <span className="mt-0.5 block text-[10px] leading-tight font-normal text-[#f7f7f4]/60">{detail}</span> : null}
        <span className="absolute top-full left-1/2 h-1.5 w-1.5 -translate-x-1/2 -translate-y-1/2 rotate-45 bg-zinc-950" />
      </span>
      {children}
    </span>
  );
}
