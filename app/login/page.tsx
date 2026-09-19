import Link from "next/link";
import { AuthForm } from "@/components/auth-form";

type Props = {
  searchParams: Promise<{ error?: string; message?: string }>;
};

export default async function LoginPage({ searchParams }: Props) {
  const params = await searchParams;

  return (
    <main className="auth-page">
      <Link href="/" className="logo-lockup">
        <span className="logo-globe">🌍</span>
        <span>
          <strong>Cuisine du monde</strong>
          <small>Voyagez. Cuisinez. Partagez.</small>
        </span>
      </Link>
      <AuthForm error={params.error} message={params.message} />
    </main>
  );
}
