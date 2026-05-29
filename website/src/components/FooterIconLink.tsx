import type { ElementType } from "react";
import { AnimatedIconTooltip } from "./AnimatedIconTooltip";

type FooterIconLinkProps = {
  href: string;
  label: string;
  detail?: string;
  icon: ElementType<{ className?: string }>;
};

export function FooterIconLink({ href, label, detail, icon: Icon }: FooterIconLinkProps) {
  return (
    <AnimatedIconTooltip label={label} detail={detail}>
      <a
        href={href}
        target="_blank"
        rel="noreferrer"
        aria-label={detail ? `${label}, ${detail}` : label}
        className="grid size-8 place-items-center rounded-sm p-1.5 font-normal text-zinc-700 hover:bg-emerald-700/10 hover:text-zinc-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600"
      >
        <Icon className="size-[18px] h-lh shrink-0 fill-current" aria-hidden="true" />
      </a>
    </AnimatedIconTooltip>
  );
}
