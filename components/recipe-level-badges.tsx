// Indicateurs visuels de difficulté (1 à 3 toques) et de piment (0 à 3 piments) d’une recette.
type Language = "fr" | "en" | "es";
type Difficulty = "easy" | "medium" | "hard";

const difficultySteps: Record<Difficulty, number> = { easy: 1, medium: 2, hard: 3 };

const labels = {
  fr: {
    difficulty: { easy: "Facile", medium: "Intermédiaire", hard: "Difficile" },
    spice: ["Pas piquant", "Légèrement piquant", "Relevé", "Très piquant"],
    difficultyTitle: "Difficulté",
    spiceTitle: "Piment",
  },
  en: {
    difficulty: { easy: "Easy", medium: "Intermediate", hard: "Challenging" },
    spice: ["Not spicy", "Mildly spicy", "Spicy", "Very hot"],
    difficultyTitle: "Difficulty",
    spiceTitle: "Heat",
  },
  es: {
    difficulty: { easy: "Fácil", medium: "Intermedia", hard: "Difícil" },
    spice: ["No picante", "Ligeramente picante", "Picante", "Muy picante"],
    difficultyTitle: "Dificultad",
    spiceTitle: "Picante",
  },
} as const;

function isDifficulty(value: string | null | undefined): value is Difficulty {
  return value === "easy" || value === "medium" || value === "hard";
}

export function spiceLevelValue(value: number | null | undefined) {
  return Math.max(0, Math.min(3, Number(value) || 0));
}

export function DifficultyBadge({
  difficulty,
  language = "fr",
  compact = false,
}: {
  difficulty: string | null | undefined;
  language?: Language;
  compact?: boolean;
}) {
  if (!isDifficulty(difficulty)) return null;
  const text = labels[language] ?? labels.fr;
  const steps = difficultySteps[difficulty];
  const label = text.difficulty[difficulty];

  return (
    <span
      className={`level-badge difficulty-badge difficulty-${difficulty}${compact ? " compact" : ""}`}
      title={`${text.difficultyTitle} : ${label}`}
      aria-label={`${text.difficultyTitle} : ${label}`}
    >
      <span className="level-icons" aria-hidden="true">
        {[1, 2, 3].map((step) => (
          <span key={step} className={step <= steps ? "level-dot on" : "level-dot"} />
        ))}
      </span>
      {compact ? null : <span>{label}</span>}
    </span>
  );
}

export function SpiceBadge({
  level,
  language = "fr",
  compact = false,
}: {
  level: number | null | undefined;
  language?: Language;
  compact?: boolean;
}) {
  const value = spiceLevelValue(level);
  const text = labels[language] ?? labels.fr;
  const label = text.spice[value];

  return (
    <span
      className={`level-badge spice-badge spice-${value}${compact ? " compact" : ""}`}
      title={`${text.spiceTitle} : ${label}`}
      aria-label={`${text.spiceTitle} : ${label}`}
    >
      <span className="level-icons" aria-hidden="true">
        {[1, 2, 3].map((step) => (
          <span key={step} className={step <= value ? "chili on" : "chili"}>🌶</span>
        ))}
      </span>
      {compact ? null : <span>{label}</span>}
    </span>
  );
}
