-- Retire des imports historiques les formats non adaptés au Web
-- ou les documents d'archive qui avaient été enregistrés comme photos de plat.
update public.recipe_images
set
  status = 'archived',
  is_primary = false,
  is_representative = false,
  moderation_notes = concat_ws(
    ' ',
    nullif(moderation_notes, ''),
    'Audit photo 2026-09-25 : format d’archive/non-web ou document ne représentant pas directement le plat.'
  )
where status = 'ready'
  and id = any (array[
    '2327516d-285e-4d9e-b54d-a8bdbfc7fd63'::uuid,
    'a7429c24-d1fc-48bb-b5be-2effdb610476'::uuid,
    '4d93ff4f-765a-4f4c-933e-71ea113df92d'::uuid,
    '62fb7b9a-0b2c-4a6f-a216-7ee2e724060a'::uuid,
    '36f2de44-d08f-49d1-b885-335669e8d7ef'::uuid,
    '591a4af6-43cf-4172-b35c-39971112d0bc'::uuid
  ]);
