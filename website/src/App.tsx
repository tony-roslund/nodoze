import { ChevronRight, Github, X } from "lucide-react";
import { GooglyEyes } from "./components/GooglyEyes";
import { MenuBarDemo } from "./components/MenuBarDemo";

export default function App() {
  return (
    <main className="isolate flex h-dvh overflow-hidden bg-[#f7f7f4] text-zinc-950 antialiased">
      <div className="mx-auto flex min-h-0 w-full max-w-6xl flex-col px-5 sm:px-8 lg:px-10">
        <header className="flex shrink-0 items-center py-5">
          <a href="#" className="flex items-center gap-2 text-base/6 font-semibold tracking-normal text-zinc-950 sm:text-sm/6">
            <GooglyEyes size="sm" />
            nodoze
          </a>
        </header>

        <section className="grid min-h-0 flex-1 grid-cols-1 items-center gap-7 pb-4 lg:grid-cols-[10fr_11fr] lg:gap-10 lg:pb-6">
          <div className="max-w-2xl">
            <GooglyEyes size="lg" />
            <p className="mt-6 text-base/7 font-medium text-emerald-700 sm:text-sm/6">Mac menu bar utility</p>
            <h1 className="mt-3 text-5xl/14 font-semibold tracking-normal text-zinc-950 sm:text-6xl/17">nodoze</h1>
            <p className="mt-4 max-w-xl text-lg/8 text-zinc-700 sm:text-base/7">
              A tiny Mac toggle that lets you close your laptop lid without putting the computer to sleep, so agents can keep working in the background.
            </p>
            <div className="mt-7 flex flex-wrap items-center gap-3">
              <a
                href="/download/nodoze-0.1.0.zip"
                className="inline-flex items-center gap-2 rounded-md bg-zinc-950 py-2.5 pr-3.5 pl-3 text-base/6 font-medium text-white ring-1 ring-zinc-950 hover:bg-zinc-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600 sm:py-2 sm:pr-3 sm:pl-2.5 sm:text-sm/6"
              >
                Download for Mac
                <ChevronRight className="size-5 sm:size-4" aria-hidden="true" />
              </a>
              <p className="text-base/7 text-zinc-600 sm:text-sm/6">Free and Open Source.</p>
            </div>
          </div>

          <div aria-label="Interactive nodoze menu bar demo">
            <MenuBarDemo />
          </div>
        </section>

        <footer className="flex shrink-0 items-center justify-between gap-4 border-t border-zinc-950/10 py-4 text-sm/6 text-zinc-600">
          <p className="hidden sm:block">MIT licensed. Built by 74Lab.</p>
          <div className="flex items-center gap-5">
            <a
              href="https://x.com/tonyroslund"
              className="inline-flex items-center gap-2 font-normal text-zinc-700 hover:text-zinc-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600"
              aria-label="Tony Roslund on X"
            >
              <X className="size-4 h-lh shrink-0" aria-hidden="true" />
              <span>@tonyroslund</span>
            </a>
            <a
              href="https://github.com/tony-roslund/nodoze"
              className="inline-flex items-center gap-2 font-normal text-zinc-700 hover:text-zinc-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600"
              aria-label="nodoze source on GitHub"
            >
              <Github className="size-4 h-lh shrink-0" aria-hidden="true" />
              <span>tony-roslund</span>
            </a>
          </div>
        </footer>
      </div>
    </main>
  );
}
