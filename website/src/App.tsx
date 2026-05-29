import { ChevronRight } from "lucide-react";
import { FaGithub, FaXTwitter } from "react-icons/fa6";
import { GooglyEyes } from "./components/GooglyEyes";
import { TopMenuBar } from "./components/TopMenuBar";

export default function App() {
  return (
    <main className="isolate flex h-dvh overflow-hidden bg-[#f7f7f4] text-zinc-950 antialiased">
      <div className="flex min-h-0 w-full flex-col">
        <TopMenuBar />

        <section className="mx-auto grid min-h-0 w-full max-w-6xl flex-1 grid-cols-1 items-center gap-7 px-5 pb-4 sm:px-8 lg:grid-cols-[10fr_11fr] lg:gap-10 lg:px-10 lg:pb-6">
          <div className="max-w-2xl">
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

          <div className="flex min-h-64 items-center justify-center lg:min-h-96" aria-label="Interactive nodoze eyes">
            <div className="scale-125 sm:scale-150 lg:scale-[2.15]">
              <GooglyEyes size="lg" />
            </div>
          </div>
        </section>

        <footer className="mx-auto flex w-full max-w-6xl shrink-0 items-center justify-between gap-4 px-5 py-4 text-sm/6 text-zinc-600 sm:px-8 lg:px-10">
          <p className="hidden sm:block">MIT licensed. Built by 74Lab.</p>
          <div className="flex items-center gap-3">
            <a
              href="https://x.com/tonyroslund"
              title="@tonyroslund"
              className="grid size-8 place-items-center font-normal text-zinc-700 hover:text-zinc-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600"
              aria-label="Tony Roslund on X, @tonyroslund"
            >
              <FaXTwitter className="size-4 h-lh shrink-0 fill-current" aria-hidden="true" />
            </a>
            <a
              href="https://github.com/tony-roslund/nodoze"
              title="tony-roslund"
              className="grid size-8 place-items-center font-normal text-zinc-700 hover:text-zinc-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600"
              aria-label="nodoze source on GitHub, tony-roslund"
            >
              <FaGithub className="size-4 h-lh shrink-0 fill-current" aria-hidden="true" />
            </a>
          </div>
        </footer>
      </div>
    </main>
  );
}
