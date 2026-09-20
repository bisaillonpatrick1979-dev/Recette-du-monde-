# Editorial recipe batch — 2026-09-20

Production database batch associated with branch `feature/home-reference-photos-and-more-recipes`.

## Coverage added

- Uruguay: Chivito uruguayo; Asado uruguayo
- Panama: Sancocho de gallina panameño; Arroz con pollo panameño
- Belize: Belizean rice and beans with stew chicken; Chimole
- Bahamas: Bahamian conch salad; Bahamian peas n' rice
- Barbados: Cou-cou and flying fish; Bajan macaroni pie
- Trinidad and Tobago: Trinidad doubles; Trinidad and Tobago callaloo
- Guyana: Guyanese pepperpot; Guyanese cook-up rice
- Suriname: Surinamese pom; Surinamese chicken roti
- Cyprus: Sheftaliés; Cypriot pork souvlaki
- Slovenia: Skutni štruklji; Kraška jota

## Data guarantees

Each recipe was inserted with:
- original title
- French, English and Spanish title translations
- ingredients with scalable numeric quantities
- preparation steps
- default servings
- country association
- editorial source URL
- Wikimedia Commons reference-photo fallback when no stored recipe image exists

After this batch the production database contains 227 published editorial recipes across 110 countries.
