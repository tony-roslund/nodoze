import { useEffect, useRef, useState } from "react";
import { BatteryFull, Check, Search, Settings, Wifi, X } from "lucide-react";
import { GooglyEyes } from "./GooglyEyes";

export function TopMenuBar() {
  const rootRef = useRef<HTMLElement>(null);
  const longPressTimer = useRef<number | null>(null);
  const longPressOpenedMenu = useRef(false);
  const [enabled, setEnabled] = useState(true);
  const [menuOpen, setMenuOpen] = useState(false);
  const [aboutOpen, setAboutOpen] = useState(false);
  const [openAtLogin, setOpenAtLogin] = useState(true);
  const [automaticUpdates, setAutomaticUpdates] = useState(true);

  useEffect(() => {
    if (!menuOpen) {
      return;
    }

    function onPointerDown(event: PointerEvent) {
      if (!rootRef.current?.contains(event.target as Node)) {
        setMenuOpen(false);
      }
    }

    function onKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setMenuOpen(false);
      }
    }

    document.addEventListener("pointerdown", onPointerDown);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("pointerdown", onPointerDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, [menuOpen]);

  function clearLongPressTimer() {
    if (longPressTimer.current != null) {
      window.clearTimeout(longPressTimer.current);
      longPressTimer.current = null;
    }
  }

  function beginPress() {
    clearLongPressTimer();
    longPressOpenedMenu.current = false;
    longPressTimer.current = window.setTimeout(() => {
      longPressOpenedMenu.current = true;
      setMenuOpen(true);
    }, 450);
  }

  function endPress(button: number, isControlClick: boolean) {
    clearLongPressTimer();

    if (button !== 0 || isControlClick) {
      longPressOpenedMenu.current = false;
      return;
    }

    if (longPressOpenedMenu.current) {
      longPressOpenedMenu.current = false;
      return;
    }

    setEnabled((value) => !value);
  }

  return (
    <header ref={rootRef} className="relative z-30 shrink-0 bg-zinc-950 p-1.5 shadow-xl shadow-zinc-950/15">
      <div className="flex h-12 items-center justify-between gap-3 bg-zinc-900 px-3 text-base/7 text-zinc-300 sm:text-sm/6">
        <div className="flex min-w-0 items-center gap-4">
          <a href="/" aria-label="Homepage" className="font-semibold text-white">
            nodoze
          </a>
          <span className="hidden text-zinc-400 sm:inline">File</span>
          <span className="hidden text-zinc-400 sm:inline">Edit</span>
          <span className="hidden text-zinc-400 md:inline">View</span>
        </div>

        <div className="flex shrink-0 items-center gap-2 sm:gap-3">
          <button
            type="button"
            aria-label={enabled ? "Disable nodoze" : "Enable nodoze"}
            aria-pressed={enabled}
            aria-expanded={menuOpen}
            title={enabled ? "nodoze is on. Right-click for settings." : "nodoze is off. Right-click for settings."}
            onPointerDown={(event) => {
              if (event.button === 0 && !event.ctrlKey) {
                beginPress();
              }
            }}
            onPointerUp={(event) => endPress(event.button, event.ctrlKey)}
            onPointerCancel={() => clearLongPressTimer()}
            onPointerLeave={() => clearLongPressTimer()}
            onKeyDown={(event) => {
              if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                setEnabled((value) => !value);
              }

              if (event.key === "ArrowDown") {
                event.preventDefault();
                setMenuOpen(true);
              }
            }}
            onContextMenu={(event) => {
              event.preventDefault();
              clearLongPressTimer();
              setMenuOpen(true);
            }}
            className="relative grid h-8 w-12 shrink-0 place-items-center focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-400"
          >
            <span className="pointer-fine:hidden absolute top-1/2 left-1/2 size-[max(100%,3rem)] -translate-1/2" aria-hidden="true" />
            <GooglyEyes enabled={enabled} size="md" />
          </button>
          <Search className="size-5 h-lh shrink-0 stroke-zinc-400 sm:size-4" aria-hidden="true" />
          <Wifi className="size-5 h-lh shrink-0 stroke-zinc-400 sm:size-4" aria-hidden="true" />
          <BatteryFull className="size-5 h-lh shrink-0 stroke-zinc-400 sm:size-4" aria-hidden="true" />
          <span className="hidden text-zinc-400 sm:inline">Fri 2:49 PM</span>
        </div>
      </div>

      {menuOpen ? (
        <div className="absolute top-[4.25rem] right-2 z-40 w-64 rounded-lg bg-zinc-100 p-2 text-zinc-950 shadow-xl shadow-zinc-950/20 ring-1 ring-zinc-950/10">
          <div className="flex items-center justify-between rounded-md px-2 py-2 text-base/7 font-medium sm:text-sm/6">
            <span>nodoze is {enabled ? "On" : "Off"}</span>
            <GooglyEyes enabled={enabled} size="sm" />
          </div>
          <button
            type="button"
            onClick={() => {
              setEnabled((value) => !value);
              setMenuOpen(false);
            }}
            className="flex w-full items-center justify-between rounded-md px-2 py-2 text-left text-base/7 text-zinc-700 hover:bg-zinc-200 sm:text-sm/6"
          >
            <span>{enabled ? "Allow Sleep on Lid Close" : "Keep Awake with Lid Closed"}</span>
          </button>
          <div className="my-1 h-px bg-zinc-200" />
          <button
            type="button"
            aria-pressed={openAtLogin}
            onClick={() => setOpenAtLogin((value) => !value)}
            className="flex w-full items-center justify-between rounded-md px-2 py-2 text-left text-base/7 text-zinc-700 hover:bg-zinc-200 sm:text-sm/6"
          >
            <span>Open at Login</span>
            {openAtLogin ? <Check className="size-4 shrink-0 stroke-zinc-950" aria-hidden="true" /> : <span className="size-4 shrink-0" aria-hidden="true" />}
          </button>
          <button
            type="button"
            aria-pressed={automaticUpdates}
            onClick={() => setAutomaticUpdates((value) => !value)}
            className="flex w-full items-center justify-between rounded-md px-2 py-2 text-left text-base/7 text-zinc-700 hover:bg-zinc-200 sm:text-sm/6"
          >
            <span>Check for Updates Automatically</span>
            {automaticUpdates ? <Check className="size-4 shrink-0 stroke-zinc-950" aria-hidden="true" /> : <span className="size-4 shrink-0" aria-hidden="true" />}
          </button>
          <div className="my-1 h-px bg-zinc-200" />
          <button
            type="button"
            onClick={() => {
              setMenuOpen(false);
              setAboutOpen(true);
            }}
            className="flex w-full items-center justify-between rounded-md px-2 py-2 text-left text-base/7 text-zinc-700 hover:bg-zinc-200 sm:text-sm/6"
          >
            <span>Settings</span>
            <Settings className="size-5 shrink-0 stroke-zinc-500 sm:size-4" aria-hidden="true" />
          </button>
          <button
            type="button"
            onClick={() => setMenuOpen(false)}
            className="flex w-full items-center justify-between rounded-md px-2 py-2 text-left text-base/7 text-zinc-700 hover:bg-zinc-200 sm:text-sm/6"
          >
            <span>Check for Updates</span>
          </button>
          <button
            type="button"
            onClick={() => {
              setMenuOpen(false);
              setAboutOpen(true);
            }}
            className="flex w-full items-center justify-between rounded-md px-2 py-2 text-left text-base/7 text-zinc-700 hover:bg-zinc-200 sm:text-sm/6"
          >
            <span>About nodoze</span>
          </button>
        </div>
      ) : null}

      {aboutOpen ? (
        <div className="fixed inset-0 z-50 grid place-items-center bg-zinc-950/35 p-5">
          <div className="w-full max-w-sm rounded-lg bg-[#f7f7f4] p-5 shadow-2xl shadow-zinc-950/30 ring-1 ring-zinc-950/10">
            <div className="flex items-start justify-between gap-4">
              <GooglyEyes enabled={enabled} size="md" />
              <button
                type="button"
                aria-label="Close about modal"
                onClick={() => setAboutOpen(false)}
                className="relative grid size-8 place-items-center rounded-md text-zinc-500 hover:bg-zinc-200 hover:text-zinc-950 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600"
              >
                <span className="pointer-fine:hidden absolute top-1/2 left-1/2 size-[max(100%,3rem)] -translate-1/2" aria-hidden="true" />
                <X className="size-5 shrink-0" aria-hidden="true" />
              </button>
            </div>
            <h2 className="mt-5 text-2xl/8 font-semibold tracking-normal text-zinc-950 sm:text-xl/8">About nodoze</h2>
            <div className="mt-3 space-y-1 text-base/7 text-zinc-700 sm:text-sm/6">
              <p>Version 0.1.0</p>
              <p>Built by 74Lab.</p>
              <p>Free and Open Source.</p>
            </div>
          </div>
        </div>
      ) : null}
    </header>
  );
}
