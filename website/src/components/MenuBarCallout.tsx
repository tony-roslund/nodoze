export function MenuBarCallout() {
  return (
    <div
      aria-hidden="true"
      className="pointer-events-none absolute top-18 right-5 z-40 h-20 w-34 text-emerald-600 sm:top-19 sm:right-24 sm:h-24 sm:w-44 lg:right-36 xl:right-42"
    >
      <p
        className="translate-y-2 -rotate-8 text-2xl/7 font-semibold tracking-normal sm:text-3xl/8"
        style={{ fontFamily: '"Bradley Hand", "Comic Sans MS", "Marker Felt", cursive' }}
      >
        this
      </p>
      <svg className="absolute -top-7 right-20 h-16 w-20 overflow-visible sm:-top-7 sm:right-10 sm:h-20 sm:w-24" viewBox="0 0 112 96" fill="none">
        <path
          d="M 19 82 C 58 80, 90 57, 84 17"
          className="stroke-emerald-600"
          strokeWidth="3.25"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M 71 26 L 84 14 L 95 29"
          className="stroke-emerald-600"
          strokeWidth="3.25"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
}
