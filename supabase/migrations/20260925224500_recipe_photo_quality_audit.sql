-- Audit des photos de recettes.
-- Retire les documents/icônes importés comme photos et quelques doublons
-- manifestement attribués au mauvais plat. Les interfaces retombent ensuite
-- sur la recherche Wikimedia stricte, qui n'affiche une image que si elle
-- correspond au nom du plat.
update public.recipe_images
set
  status = 'archived',
  is_primary = false,
  is_representative = false,
  moderation_notes = concat_ws(
    ' ',
    nullif(moderation_notes, ''),
    'Audit photo 2026-09-25 : image retirée car elle ne représente pas exactement la recette ou n’est pas une photo raster du plat.'
  )
where status = 'ready'
  and (
    external_url ~* '[.](pdf|svg)([?]|$)'
    or id = any (array[
      '2855ddd2-1e5a-4a70-a43a-86fb7b516ea2'::uuid,
      '2d9bd203-aaae-4647-a316-df6b738a04a8'::uuid,
      '93597aa7-fad2-4781-b4c5-c8383147c453'::uuid,
      'aaf5ed4b-361d-498b-8d5e-d431c39c52bb'::uuid,
      '66d2b666-a02e-4d82-84fc-3d4663509510'::uuid,
      '6ff3d5b3-6433-43aa-8b7e-fe5695497aa2'::uuid,
      '9470e6d8-04be-4f21-985f-39ccb1c9c129'::uuid,
      'd290e620-3ba9-4a58-8bea-6c97ad75579a'::uuid,
      '62f8033d-ee2e-427f-9c70-4c3c135fc9a6'::uuid,
      'ef49d195-9f42-4cb7-8105-2cf26220e226'::uuid,
      '7a62cc36-9f66-43b7-9cdf-248af6abdfdd'::uuid,
      '66eb7a05-73c9-41bb-a494-875831d3dd59'::uuid,
      '06211134-462a-475c-9b4d-35fb1bff53f3'::uuid,
      '6ca1e9d1-a38d-47eb-81e2-440b77048a4b'::uuid,
      'a3eddee8-cd41-40ce-8528-f3fb145fb7a1'::uuid,
      'b5a15dc7-de6c-4ff6-919b-f1612e8f69d3'::uuid
    ])
  );
