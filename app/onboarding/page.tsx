import { OnboardingWizard } from "@/components/onboarding-wizard";

export default function OnboardingPage() {
  return (
    <main className="onboarding-page">
      <section className="onboarding-brand">
        <div className="brand-mark" aria-hidden="true">🌍</div>
        <div>
          <p className="eyebrow">Bienvenue</p>
          <h1>Cuisine du monde</h1>
          <p className="muted">Voyagez. Cuisinez. Partagez.</p>
        </div>
      </section>
      <OnboardingWizard />
    </main>
  );
}
